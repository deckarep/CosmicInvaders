const std = @import("std");
const c = @import("cdefs.zig").c;
const conf = @import("conf.zig");
const fnts = @import("resources.zig").Resources.Fonts;
const esngs = @import("easings.zig");
const state = @import("gamestate.zig");

const duration = 30;

const initialPos = 0;
const destPos = 200;
const returnPos = -400;

pub const WaveBannerState = enum {
    Initial,
    FlyDown,
    ScaleUp,
    Stable,
    ScaleDn,
    FlyUp,
};

pub const WaveBanner = struct {
    mX: f32 = conf.WIN_WIDTH / 2.0,
    mY: f32 = 0,

    mXScale: f32 = 1.0,
    mYScale: f32 = 0.0,

    bannerRenderTexture: ?c.RenderTexture = null,

    mWaveCount: usize,
    mState: WaveBannerState = .Initial,
    mStateFrames: usize = 0,

    const Self = @This();

    pub fn create(waveCount: usize) Self {
        return Self{
            .mWaveCount = waveCount,
        };
    }

    pub fn deinit(self: *Self) void {
        if (self.bannerRenderTexture) |rt| {
            c.UnloadRenderTexture(rt);
        }
    }

    pub fn showWave(self: *Self, waveCount: usize) !void {
        self.mWaveCount = waveCount;
        try self.fontToRenderTexture();
        self.mState = .FlyDown;
    }

    pub fn fontToRenderTexture(self: *Self) !void {
        // 1. Clear out old texture if one exists.
        if (self.bannerRenderTexture) |rt| {
            c.UnloadRenderTexture(rt);
        }

        // 2. Clear as fully transparent.
        c.ClearBackground(c.Color{ .r = 0xff, .g = 0x00, .b = 0x00, .a = 0xff });

        var buf: [16]u8 = undefined;
        const fontSize = 35;
        const fontSpacing = 1;

        const text = try std.fmt.bufPrintZ(buf[0..], "WAVE {d}", .{self.mWaveCount + 1});
        const dims = c.MeasureTextEx(fnts.Font1, text, fontSize, fontSpacing);

        // Create new render texture.
        self.bannerRenderTexture = c.LoadRenderTexture(@intFromFloat(dims.x), @intFromFloat(dims.y));
        c.BeginTextureMode(self.bannerRenderTexture.?);
        defer c.EndTextureMode();

        c.DrawTextEx(
            fnts.Font1,
            text,
            .{
                // Correct for half the font size, after being measured.
                .x = 0, //self.mX - (dims.x / 2.0),
                .y = 0, //self.mY,
            },
            fontSize,
            fontSpacing,
            conf.FontColor.Red,
        );
    }

    fn pumpFrames(self: *Self, dur: usize, targetState: WaveBannerState) void {
        if (self.mStateFrames >= dur) {
            self.mStateFrames = 0;
            self.mState = targetState;
        } else {
            self.mStateFrames += 1;
        }
    }

    pub fn update(self: *Self) !void {
        switch (self.mState) {
            .Initial => {
                self.mYScale = 0.0;
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
                self.pumpFrames(duration, .ScaleUp);
            },
            .ScaleUp => {
                const start = 0.0;
                const end = 1.0 - start;
                self.mYScale = esngs.easeOutCubic(
                    @floatFromInt(self.mStateFrames),
                    start,
                    end,
                    @floatFromInt(duration),
                );
                self.pumpFrames(duration, .Stable);
            },
            .Stable => {
                self.mYScale = 1.0;
                self.pumpFrames(duration + 30, .ScaleDn);
            },
            .ScaleDn => {
                const start = 1.0;
                const end = 0.0 - start;
                self.mYScale = esngs.easeOutCubic(
                    @floatFromInt(self.mStateFrames),
                    start,
                    end,
                    @floatFromInt(duration),
                );
                self.pumpFrames(duration, .FlyUp);
            },
            .FlyUp => {
                const start = destPos;
                const end = -40 - start;
                self.mY = esngs.easeOutCubic(
                    @floatFromInt(self.mStateFrames),
                    @floatFromInt(start),
                    @floatFromInt(end),
                    @floatFromInt(duration),
                );
                self.pumpFrames(duration, .Initial);
            },
        }
    }

    pub fn draw(self: Self) !void {
        if (self.mState == .Initial) return;

        if (self.bannerRenderTexture) |brt| {
            const rtWidth: f32 = @floatFromInt(brt.texture.width);
            const rtHeight: f32 = @floatFromInt(brt.texture.height);
            const src = c.Rectangle{ .x = 0, .y = 0, .width = rtWidth, .height = -rtHeight };
            const dst = c.Rectangle{ .x = 0, .y = 0, .width = rtWidth, .height = rtHeight * self.mYScale };

            c.DrawTexturePro(
                brt.texture,
                src,
                dst,
                // With render texture everything has to be negated.
                c.Vector2{
                    .x = (-conf.WIN_WIDTH / 2.0) + (@as(f32, rtWidth) / 2.0),
                    .y = -self.mY,
                },
                0,
                c.WHITE,
            );
        }
    }
};
