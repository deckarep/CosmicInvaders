const std = @import("std");
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

// NOTE: Probably going to delete this...as it's currently unfinished and unused and now
// unecessary!
pub fn loadAllegroFont(imgFontPath: [:0]const u8, allocator: std.mem.Allocator) !c.Font {
    var font = std.mem.zeroes(c.Font);
    font.texture = c.LoadTexture(imgFontPath);
    font.baseSize = 10;
    const charCount = 95;
    font.glyphCount = charCount; // need to count this actually.

    const glyphsSlice = try allocator.alloc(c.GlyphInfo, charCount);
    font.glyphs = glyphsSlice.ptr;
    const recsSlice = try allocator.alloc(c.Rectangle, charCount);
    font.recs = recsSlice.ptr;

    const charsPerRow = 16;
    const charWidth = 8;
    const charHeight = 10;

    for (0..charCount) |i| {
        font.glyphs[i].value = 32 + @as(i32, @intCast(i)); // Character value (Unicode)

        // Compute grid position
        const col = @as(f32, @floatFromInt(i % charsPerRow));
        const row = @as(f32, @floatFromInt(i / charsPerRow));
        const yPadding = 1;

        // Character bounds
        font.recs[i] = c.Rectangle{
            .x = col * charWidth,
            .y = (row * (charHeight + yPadding)),
            .width = charWidth,
            .height = charHeight + yPadding,
        };

        // Remaining can be left as 0.
        font.glyphs[i].offsetX = 0; // Character offset X when drawing
        font.glyphs[i].offsetY = 0; // Character offset Y when drawing
        font.glyphs[i].advanceX = 0; // Character advance position X
        //font.glyphs[i].image = null; // Character pixel data (grayscale)
    }

    const h = 10;
    font.recs[0] = .{ .x = 1, .y = 1, .width = 4, .height = h };
    font.recs[0] = .{ .x = 6, .y = 1, .width = 5, .height = h };
    font.recs[0] = .{ .x = 12, .y = 1, .width = 8, .height = h };
    font.recs[0] = .{ .x = 1, .y = 1, .width = 9, .height = h };
    font.recs[0] = .{ .x = 1, .y = 1, .width = 9, .height = h };
    font.recs[0] = .{ .x = 1, .y = 1, .width = 8, .height = h };
    font.recs[0] = .{ .x = 1, .y = 1, .width = 8, .height = h };
    font.recs[0] = .{ .x = 1, .y = 1, .width = 5, .height = h };
    font.recs[0] = .{ .x = 1, .y = 1, .width = 4, .height = h };
    font.recs[0] = .{ .x = 1, .y = 1, .width = 4, .height = h };
    font.recs[0] = .{ .x = 1, .y = 1, .width = 4, .height = h };
    font.recs[0] = .{ .x = 1, .y = 1, .width = 4, .height = h };
    font.recs[0] = .{ .x = 1, .y = 1, .width = 4, .height = h };
    font.recs[0] = .{ .x = 1, .y = 1, .width = 4, .height = h };
    font.recs[0] = .{ .x = 1, .y = 1, .width = 4, .height = h };
    font.recs[0] = .{ .x = 1, .y = 1, .width = 4, .height = h };

    return font;
}
