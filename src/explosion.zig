const c = @import("c");
const drw = @import("draw.zig");
const state = @import("game_state.zig");

pub const ExplosionKind = enum {
    Inplace, // Inplace explosions, just explode and stay in position.
    Rising, // Rising explosions migrate towards the sky like a real explosion.
};

pub const Explosion = struct {
    mKind: ExplosionKind = .Inplace,
    mPos: c.Vector2,
    mTexture: c.Texture,
    mTotalFrames: usize,
    mCurrentFrame: usize = 0,
    mEnded: bool = false,

    const Self = @This();

    pub fn create(x: f32, y: f32, totalFrames: usize, texture: c.Texture) Self {
        return Self{
            .mPos = .{
                .x = x,
                .y = y,
            },
            .mTotalFrames = totalFrames,
            .mTexture = texture,
        };
    }

    pub fn setKind(self: *Self, kind: ExplosionKind) void {
        self.mKind = kind;
    }

    pub inline fn ended(self: Self) bool {
        return self.mEnded;
    }

    pub fn update(self: *Self) !void {
        if (self.ended()) return;

        switch (self.mKind) {
            .Inplace => {},
            .Rising => self.mPos.y -= 1,
        }

        const everyNFrameRate = 5;
        if ((state.mGame.mTicks % everyNFrameRate) == 0) {
            self.mCurrentFrame += 1;
            if (self.mCurrentFrame == self.mTotalFrames) {
                self.mEnded = true;
            }
        }
    }

    pub fn draw(self: Self) void {
        if (self.ended()) return;

        // WARN: hardcoded bullshit.
        // poof
        var w: f32 = 18;
        var h: f32 = 18;

        if (self.mTexture.height == 24) {
            // explosion_small
            w = 17;
            h = 24;
        } else if (self.mTexture.height == 15) {
            // puff2
            w = 11;
            h = 15;
        }

        const hw = w / 2.0;
        const hh = h / 2.0;

        const xOffset: f32 = @as(f32, @floatFromInt(self.mCurrentFrame)) * w;
        const yOffset: f32 = h * 0;

        const view = c.Rectangle{
            .x = xOffset,
            .y = yOffset,
            .width = w,
            .height = h,
        };

        // NOTE: Subtracting half w/h this way placement is centered for the explosion.
        drw.drawTextureScaled(self.mPos.x - hw, self.mPos.y - hh, self.mTexture, view, 2.0, c.WHITE);
    }
};
