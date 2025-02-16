const std = @import("std");
const state = @import("game_state.zig");
const c = @import("cdefs.zig").c;
const drw = @import("draw.zig");
const res = @import("resources.zig");
const conf = @import("conf.zig");

pub const WeaponStationKind = enum(u8) {
    Canon,
    TeslaCoil,
    RocketLauncher,
};

pub const StationCondition = enum(u8) {
    New,
    Firing,
    Exploding, // Show explosion, various fire-balls and sharapnel.
    Dead, // Actually reap the object.
};

pub const WeaponStation = struct {
    mKind: WeaponStationKind,
    mCondition: StationCondition = .New,
    mX: f32 = 180,
    mY: f32 = 372,
    mHealth: u8 = 100, // express as percent or some other unit?
    mFireCountdown: usize = 0,

    const Self = @This();

    pub fn create(kind: WeaponStationKind) Self {
        const countdown: usize = switch (kind) {
            .Canon => conf.CanonCooldown,
            .TeslaCoil => conf.TeslaCoilCooldown,
            .RocketLauncher => conf.RocketLauncherCooldown,
        };

        return Self{
            .mKind = kind,
            .mFireCountdown = countdown,
        };
    }

    pub fn update(self: *Self) !void {
        self.mFireCountdown -= 1;
        const shouldFire = self.mFireCountdown == 0;

        switch (self.mKind) {
            .Canon => {
                if (shouldFire) {
                    const x = self.mX + ((29 * 2) / 2);
                    try state.mGame.spawnCanonBullet(x, self.mY);
                    c.PlaySound(res.Resources.Sfx.LaserFire);
                    self.mFireCountdown = conf.CanonCooldown;
                }
            },
            .TeslaCoil => {
                if (shouldFire) {
                    self.mFireCountdown = conf.CanonCooldown;
                }
            },
            .RocketLauncher => {
                if (shouldFire) {
                    self.mFireCountdown = conf.CanonCooldown;
                }
            },
        }
    }

    // This returns the true bounding box.
    pub fn getTrueBounds(self: Self) c.Rectangle {
        const scale = 2.0;

        const wh = switch (self.mKind) {
            .Canon => c.Vector2{ .x = 29, .y = 29 },
            // Below values are hardcoded for now.
            .TeslaCoil => c.Vector2{ .x = 29, .y = 29 },
            .RocketLauncher => c.Vector2{ .x = 29, .y = 29 },
        };

        return c.Rectangle{
            .x = self.mX,
            .y = self.mY,
            .width = wh.x * scale,
            .height = wh.y * scale,
        };
    }

    // This returns the fudged bounding box, that's been tightened up
    // for more accurate hitbox detection.
    pub inline fn getBounds(self: Self) c.Rectangle {
        var rect = self.getTrueBounds();

        switch (self.mKind) {
            .Canon => {
                rect.x += 10;
                rect.width -= 20;
                rect.y += 20;
                rect.height -= 20;
            },
            .TeslaCoil => {},
            .RocketLauncher => {},
        }

        return rect;
    }

    pub fn sell(self: *Self) void {
        _ = self;
        // TODO: compute and return salvage value, and destroy object.
    }

    pub fn repair(self: *Self) void {
        self.mHealth = 100;
        self.mCondition = .New;
    }

    pub inline fn dead(self: Self) bool {
        return self.mHealth <= 0;
    }

    pub fn checkHit(self: *Self, projBounds: c.Rectangle, amount: u8) bool {
        if (self.dead()) return false;

        if (c.CheckCollisionRecs(projBounds, self.getBounds())) {
            self.mHealth -= amount;

            return true;
        }

        return false;
    }

    fn drawSmokePlume(self: Self, bounds: c.Rectangle) void {
        if (self.mHealth > 33) return;

        // The smoke plume animates faster as health decreases.
        const speed: usize = @intFromFloat(std.math.lerp(2.0, 15.0, @as(f32, @floatFromInt(self.mHealth)) / 100.0));

        const numFrames = 7;
        const frameIdx: f32 = @as(f32, @floatFromInt((state.mGame.mTicks / speed) % (numFrames)));
        const w: f32 = 11;
        const h: f32 = @floatFromInt(res.Resources.Effects.Puff2.height);
        const view = c.Rectangle{ .x = frameIdx * w, .y = 0, .width = w, .height = h };
        drw.drawTextureScaled(
            // NOTE: the frameIdx is also used to offset the x/y anchor a tad as the animation progresses.
            bounds.x + bounds.width - 25 + frameIdx,
            bounds.y - 10 - (frameIdx * 2),
            res.Resources.Effects.Puff2,
            view,
            2.0,
        );
    }

    fn drawHealthBar(self: Self, bounds: c.Rectangle) void {
        // Draw health box.
        const health = (@as(f32, @floatFromInt(self.mHealth)) * bounds.width) / 100.0;

        c.DrawRectangle(
            @intFromFloat(bounds.x),
            @intFromFloat(bounds.y + bounds.height + 2),
            @intFromFloat(health),
            @intFromFloat(6),
            c.GREEN,
        );

        c.DrawRectangleLines(
            @intFromFloat(bounds.x),
            @intFromFloat(bounds.y + bounds.height + 2),
            @intFromFloat(bounds.width),
            @intFromFloat(6),
            c.RED,
        );
    }

    pub fn draw(self: Self) !void {
        if (self.dead()) return;

        // TODO: when below some mHealth threshold, show damage animation as well.
        // Giving the user an indication that there structure will be destroyed soon!
        switch (self.mKind) {
            .Canon => {
                const w = 29;
                const h = 29;
                //const frameSeqCount = 7;
                // const halfFrameSeqCount = frameSeqCount / 2;
                // const speedReduceFactor = 6;
                // const phase = (((state.mGame.mTicks) / speedReduceFactor)) % frameSeqCount;
                // const value = if (phase > halfFrameSeqCount) frameSeqCount - phase else phase;
                // const xOffset: f32 = @floatFromInt(value * w);
                // const yOffset: f32 = @floatFromInt(h * 0);
                const view = c.Rectangle{ .x = 0, .y = 0, .width = w, .height = h };
                drw.drawTextureScaled(
                    self.mX,
                    self.mY,
                    res.Resources.Canon,
                    view,
                    2.0,
                );

                const bounds = self.getBounds();

                // Draw low damage puff indicator when health is below threshold.
                self.drawSmokePlume(bounds);

                // Draw health box.
                self.drawHealthBar(bounds);

                // Draw hit box
                c.DrawRectangleLines(
                    @intFromFloat(bounds.x),
                    @intFromFloat(bounds.y),
                    @intFromFloat(bounds.width),
                    @intFromFloat(bounds.height),
                    c.RED,
                );
            },
            .TeslaCoil => {
                // TODO
            },
            .RocketLauncher => {
                // TODO
            },
        }
    }
};
