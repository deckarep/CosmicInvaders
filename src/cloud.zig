const std = @import("std");
const c = @import("cdefs.zig").c;
const drw = @import("draw.zig");
const conf = @import("conf.zig");
const state = @import("gamestate.zig");

const CloudMinY = 80;
const CloudMaxY = 120;

pub const Cloud = struct {
    mTexture: c.Texture,
    mXSpeed: f32 = 0,
    mX: f32 = 0,
    mY: f32 = 0,

    const Self = @This();

    pub fn init(texture: c.Texture) Cloud {
        return Cloud{
            .mTexture = texture,
            .mXSpeed = @floatFromInt(c.GetRandomValue(1, 6)),
            .mX = @floatFromInt(c.GetRandomValue(0, conf.WIN_WIDTH)),
            .mY = @floatFromInt(c.GetRandomValue(CloudMinY, CloudMaxY)),
        };
    }

    pub fn update(self: *Self) void {
        self.mX -= self.mXSpeed * c.GetFrameTime();

        // The clouds move left, if they are past their width beyond 0, wrap them around.
        if (self.mX < @as(f32, @floatFromInt(-self.mTexture.width)) * 2.0) {
            self.mX = conf.WIN_WIDTH;
            // And additionally choose a new y-Axis.
            self.mY = @floatFromInt(c.GetRandomValue(CloudMinY, CloudMaxY));
        }
    }

    pub fn draw(self: Self) void {
        const view = c.Rectangle{
            .x = 0,
            .y = 0,
            .width = @floatFromInt(self.mTexture.width),
            .height = @floatFromInt(self.mTexture.height),
        };

        drw.drawTextureScaled(self.mX, self.mY, self.mTexture, view, 2.0);
    }
};
