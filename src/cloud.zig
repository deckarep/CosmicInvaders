const std = @import("std");
const c = @import("c");
const drw = @import("draw.zig");
const conf = @import("conf.zig");
const state = @import("game_state.zig");

const CloudMinY = 80;
const CloudMaxY = 120;

pub const Cloud = struct {
    mTexture: c.Texture,
    mXSpeed: f32 = 0,
    mPos: c.Vector2 = .{ .x = 0, .y = 0 },

    const Self = @This();

    pub fn init(texture: c.Texture) Self {
        return Self{ .mTexture = texture, .mXSpeed = @floatFromInt(c.GetRandomValue(1, 6)), .mPos = .{
            .x = @floatFromInt(c.GetRandomValue(0, conf.WIN_WIDTH)),
            .y = @floatFromInt(c.GetRandomValue(CloudMinY, CloudMaxY)),
        } };
    }

    pub fn update(self: *Self) void {
        self.mPos.x -= self.mXSpeed * c.GetFrameTime();

        // The clouds move left, if they are past their width beyond 0, wrap them around.
        if (self.mPos.x < @as(f32, @floatFromInt(-self.mTexture.width)) * 2.0) {
            self.mPos.x = conf.WIN_WIDTH;
            // And additionally choose a new y-Axis.
            self.mPos.y = @floatFromInt(c.GetRandomValue(CloudMinY, CloudMaxY));
        }
    }

    pub fn draw(self: Self) void {
        const view = c.Rectangle{
            .x = 0,
            .y = 0,
            .width = @floatFromInt(self.mTexture.width),
            .height = @floatFromInt(self.mTexture.height),
        };

        drw.drawTextureScaled(self.mPos.x, self.mPos.y, self.mTexture, view, 2.0, c.WHITE);
    }
};
