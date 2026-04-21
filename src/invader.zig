const std = @import("std");
const state = @import("game_state.zig");
const conf = @import("conf.zig");
const res = @import("resources.zig");
const pj = @import("projectile.zig");
const drw = @import("draw.zig");
const esngs = @import("easings.zig");
const c = @import("c");

pub const InvWidth = 16 * 2;
pub const InvHeight = 13 * 2;

pub const InvaderDeathReason = enum(u8) {
    HitGround,
    HitWeaponStation,
    PlayerProjectile,
};

pub const InvaderState = enum(u8) {
    Ok, // Initial state, green no damage yet.
    Damaged, // When a projectile hits.
    Marked, // Hit at least once, marked and vulnerable.
};

pub const Invader = struct {
    mX: f32 = 0,
    mY: f32 = 0,
    mHits: usize = 2,

    mFlickerCount: usize = FlickerFrames,
    mState: InvaderState = .Ok,
    mViewYOffset: f32 = 0,

    // If null, invader is not dead.
    mDeathReason: ?InvaderDeathReason = null,

    const FlickerFrames = 10;
    const Self = @This();

    pub fn update(self: *Self) void {
        switch (self.mState) {
            .Ok => {
                self.mViewYOffset = 0;
            },
            .Damaged => {
                // BUG: for some reason I don't always see the flicker render.
                self.mViewYOffset = if (self.mFlickerCount % 3 == 0) 0 else 1;

                if (self.mFlickerCount <= 0) {
                    self.mFlickerCount = FlickerFrames;
                    self.mState = .Marked;
                } else {
                    self.mFlickerCount -= 1;
                }
            },
            .Marked => {
                self.mViewYOffset = 2;
            },
        }
    }

    pub fn draw(self: Self) void {
        const width = 16;
        const height = 13;
        const frameSeqCount = 6;
        const halfFrameSeqCount = frameSeqCount / 2;
        const speedReduceFactor = 10;
        const scale = 2.0;

        // Division is used to slow the ticks down a bit.
        // Using ticks as a stream of numbers, generates 0-5 inclusive
        // Using the idx, causes the animations to offset by idx number.
        const phase = (((state.mGame.mTicks) / speedReduceFactor)) % frameSeqCount;
        // Then the upper half of the numbers are subtracted from 6, to create a
        // repeating pattern that goes up and down in sequence.
        const value = if (phase > halfFrameSeqCount) frameSeqCount - phase else phase;
        const xOffset: f32 = @floatFromInt(value * width);
        const yOffset: f32 = @as(f32, @floatFromInt(height)) * self.mViewYOffset;

        const view = c.Rectangle{
            .x = xOffset,
            .y = yOffset,
            .width = width,
            .height = height,
        };

        drw.drawTextureScaled(
            self.mX,
            self.mY,
            res.Resources.Invader1,
            view,
            scale,
        );

        // Debug inv bounds.
        const invBounds = self.getBounds();
        c.DrawRectangleLines(
            @intFromFloat(invBounds.x),
            @intFromFloat(invBounds.y),
            @intFromFloat(invBounds.width),
            @intFromFloat(invBounds.height),
            c.RED,
        );
    }

    pub inline fn getPos(self: Self) c.Vector2 {
        return c.Vector2{ .x = self.mX, .y = self.mY };
    }

    pub inline fn getBounds(self: Self) c.Rectangle {
        return c.Rectangle{
            .x = self.mX,
            .y = self.mY,
            .width = InvWidth,
            .height = InvHeight,
        };
    }

    pub inline fn dead(self: Self) bool {
        return self.mDeathReason != null;
    }

    pub fn checkHit(self: *Self, projBounds: c.Rectangle) bool {
        const invBounds = self.getBounds();

        const collided = c.CheckCollisionRecs(projBounds, invBounds);
        if (collided) {
            self.mHits -= 1;

            // Put the invader into damaged mode.
            self.mState = .Damaged;

            if (self.mHits == 0) {
                self.mDeathReason = .PlayerProjectile;
            }
        }

        return collided;
    }
};
