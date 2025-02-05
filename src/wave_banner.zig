const std = @import("std");
const c = @import("cdefs.zig").c;
const conf = @import("conf.zig");
const fnts = @import("textures.zig").Textures.Fonts;
const esngs = @import("easings.zig");
const state = @import("gamestate.zig");

const duration = 30;
const initialPos = 0;
const destPos = 200;
const returnPos = -400;

pub const WaveBannerState = enum {
    Initial,
    FlyDown,
    Mid,
    FlyUp,
};

pub const WaveBanner = struct {
    mX: f32 = conf.WIN_WIDTH / 2.0,
    mY: f32 = 0,
    mWaveCount: usize,
    mState: WaveBannerState = .Initial,
    mStateFrames: usize = 0,

    const Self = @This();

    pub fn create(waveCount: usize) Self {
        return Self{
            .mWaveCount = waveCount,
        };
    }

    pub fn showWave(self: *Self, waveCount: usize) void {
        self.mWaveCount = waveCount;
        self.mState = .FlyDown;
    }

    pub fn update(self: *Self) void {
        switch (self.mState) {
            .Initial => {
                self.mY = 0;
                self.mStateFrames = 0;
            },
            .FlyDown => {
                self.mY = esngs.easeOutQuart(
                    @floatFromInt(self.mStateFrames),
                    @floatFromInt(initialPos),
                    @floatFromInt(destPos),
                    @floatFromInt(duration),
                );
                if (self.mStateFrames >= duration) {
                    self.mStateFrames = 0;
                    self.mState = .Mid;
                } else {
                    self.mStateFrames += 1;
                }
            },
            .Mid => {
                if (self.mStateFrames >= duration) {
                    self.mState = .FlyUp;
                    self.mStateFrames = 0;
                } else {
                    self.mStateFrames += 1;
                }
            },
            .FlyUp => {
                self.mY = esngs.easeOutCubic(
                    @floatFromInt(self.mStateFrames),
                    @floatFromInt(destPos),
                    @floatFromInt(-300),
                    @floatFromInt(duration),
                );
                if (self.mStateFrames >= duration) {
                    self.mStateFrames = 0;
                    self.mState = .Initial;
                } else {
                    self.mStateFrames += 1;
                }
            },
        }
    }

    pub fn draw(self: Self) !void {
        if (self.mState == .Initial) return;

        var buf: [8]u8 = undefined;
        const fontSize = 50;
        const fontSpacing = 1;

        const text = try std.fmt.bufPrintZ(buf[0..], "WAVE {d}", .{self.mWaveCount + 1});
        const dims = c.MeasureTextEx(fnts.Font1, text, fontSize, fontSpacing);

        c.DrawTextEx(
            fnts.Font1,
            text,
            .{
                // Correct for half the font size, after being measured.
                .x = self.mX - (dims.x / 2.0),
                .y = self.mY,
            },
            fontSize,
            fontSpacing,
            conf.FontColor.Red,
        );
    }
};
