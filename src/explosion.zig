const c = @import("cdefs.zig").c;
const drw = @import("draw.zig");
const state = @import("gamestate.zig");

pub const Explosion = struct {
    mX: f32,
    mY: f32,
    mTexture: c.Texture = undefined,
    currentFrame: usize = 0,
    ended: bool = false,

    const Self = @This();

    pub fn create(x: f32, y: f32, texture: c.Texture) Self {
        return Self{
            .mX = x,
            .mY = y,
            .mTexture = texture,
        };
    }

    pub fn update(self: *Self) !void {
        if (self.ended) return;

        if ((state.mGame.mTicks % 2) == 0) {
            self.currentFrame += 1;
            if (self.currentFrame == 7) {
                self.ended = true;
            }
        }
    }

    pub fn draw(self: Self) void {
        if (self.ended) return;

        const w = 18;
        const h = 18;
        //const frameSeqCount = 7;
        // const speedReduceFactor = 6;
        //const value = (((state.mGame.mTicks) / speedReduceFactor)) % frameSeqCount;
        const value = self.currentFrame;
        const xOffset: f32 = @floatFromInt(value * w);
        const yOffset: f32 = @floatFromInt(h * 0);
        const view = c.Rectangle{ .x = xOffset, .y = yOffset, .width = w, .height = h };

        drw.drawTextureScaled(self.mX, self.mY, self.mTexture, view, 2.0);
    }
};
