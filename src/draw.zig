const c = @import("cdefs.zig").c;

pub fn drawTextureScaled(x: f32, y: f32, texture: c.Texture, view: c.Rectangle, scale: f32) void {
    const src = c.Rectangle{
        .x = view.x,
        .y = view.y,
        .width = view.width,
        .height = view.height,
    };
    const dst = c.Rectangle{
        .x = x,
        .y = y,
        .width = view.width * scale,
        .height = view.height * scale,
    };

    c.DrawTexturePro(
        texture,
        src,
        dst,
        c.Vector2{ .x = 0, .y = 0 },
        0,
        c.WHITE,
    );
}
