const c = @import("cdefs.zig").c;
const conf = @import("conf.zig");
const drw = @import("draw.zig");
const fnts = @import("textures.zig").Textures.Fonts;

pub const ScoreStyle = enum {
    MiniRed,
};

pub const FloatingScore = struct {
    mX: f32 = 0,
    mY: f32 = 0,
    mLifetime: usize = 30,
    mText: [:0]const u8,
    mKind: ScoreStyle,

    const Self = @This();

    pub fn create(text: [:0]const u8, x: f32, y: f32, kind: ScoreStyle) Self {
        return Self{
            .mX = x,
            .mY = y,
            .mText = text,
            .mKind = kind,
        };
    }

    pub inline fn ended(self: Self) bool {
        return self.mLifetime <= 0;
    }

    pub fn update(self: *Self) void {
        if (self.mLifetime <= 0) return;

        self.mLifetime -= 1;

        switch (self.mKind) {
            .MiniRed => {
                const movement = 4.0 * c.GetFrameTime();
                self.mY -= movement;
                self.mX += movement;
            },
        }
    }

    pub fn draw(self: Self) void {
        if (self.mLifetime <= 0) return;

        switch (self.mKind) {
            .MiniRed => {
                c.DrawTextEx(
                    fnts.Font1,
                    self.mText,
                    .{ .x = self.mX, .y = self.mY },
                    10,
                    2,
                    conf.FontColor.Red,
                );
            },
        }
    }
};
