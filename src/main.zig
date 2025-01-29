const std = @import("std");
const zigimg = @import("zigimg");
const c = @import("cdefs.zig").c;

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const alloc = gpa.allocator();

// Note: requires Zig 0.14.0-dev or higher so far.

const KeyOutHotPink = zigimg.color.Rgb24.initRgb(255, 0, 255);
const KeyOutFontBlue = zigimg.color.Rgb24.initRgb(141, 192, 219);

const mzFiles: []const [:0]const u8 = &.{
    // Single bitmaps
    "data/bg.mz",
    "data/cloud1.mz",
    "data/cloud2.mz",
    "data/cloud3.mz",
    "data/cloud4.mz",
    "data/cloud5.mz",
    "data/debris.mz",
    "data/font_big.mz",
    "data/font_big_red.mz",
    "data/font_small.mz",
    "data/font_small_red.mz",
    "data/icons.mz",
    "data/laser_medium.mz",
    "data/laser_small.mz",
    "data/orb1.mz",
    "data/orb2.mz",
    "data/orb3.mz",
    "data/redbar.mz",
    "data/selector.mz",
    "data/slots.mz",
    "data/turret2.mz",
    "data/turret3.mz",
    "data/upgrade_icons.mz",

    // Sprites are just bitmaps with subsections.
    // NOTE: Here they are extracted as bitmaps but if we were to go
    // all the way, these files have additional zlib encoded values
    // which contain the sub-bitmap dimensions using the allegro42.create_sub_bitmap function.
    "data/alienbullet.sz",
    "data/explosion_small.sz",
    "data/invader1.sz",
    "data/invader2.sz",
    "data/missile.sz",
    "data/orb4.sz",
    "data/orbbomb.sz",
    "data/poof.sz",
    "data/puff1.sz",
    "data/puff2.sz",
    "data/turret1.sz",
    "data/turret2.sz",
    "data/turret3.sz",
};

fn gzgetshort(file: c.gzFile) i32 {
    const a = c.gzgetc(file);
    return (c.gzgetc(file) << 8) | a;
}

fn color24Eq(a: zigimg.color.Rgb24, b: zigimg.color.Rgb24) bool {
    return a.r == b.r and a.g == b.g and a.b == b.b;
}

pub fn main() !void {
    // Prints to stderr (it's a shortcut based on `std.io.getStdErr()`)
    std.debug.print("All your {s} are belong to us.\n", .{"codebase"});

    for (mzFiles) |path| {
        try genBitmapFile(path, alloc);
    }
}

fn genBitmapFile(path: [:0]const u8, allocator: std.mem.Allocator) !void {
    const f = c.gzopen(path, "rb");
    if (f == null) {
        @panic("failed to open file!");
    }

    const width = gzgetshort(f);
    const height = gzgetshort(f);

    var img = try zigimg.Image.create(
        allocator,
        @intCast(width),
        @intCast(height),
        .rgba32,
    );
    defer img.deinit();

    for (0..@intCast(width)) |y| { // Row-major iteration.
        for (0..@intCast(height)) |x| { // Iterate across the row.
            const r: u8 = @intCast(c.gzgetc(f));
            const g: u8 = @intCast(c.gzgetc(f));
            const b: u8 = @intCast(c.gzgetc(f));

            const color = zigimg.color.Rgb24.initRgb(r, g, b);

            // Although these assets use rgb24 colors, we generate rgba32 colors
            // and when we observe the key-out colors (like hot-pink) of games from
            // this era, we just set the alpha to 0 otherwise it remains 255.
            var a: u8 = 255;

            // Check for KeyOut colors
            if (color24Eq(color, KeyOutHotPink) or
                (color24Eq(color, KeyOutFontBlue) and std.mem.startsWith(u8, path, "data/font_")))
            {
                a = 0; // Knock out color by setting alpha to 0
            }

            // Ensure we index correctly within bounds
            const index = (y * @as(usize, @intCast(height))) + x;
            img.pixels.rgba32[index] = zigimg.color.Rgba32.initRgba(r, g, b, a);
        }
    }

    var buf: [32]u8 = undefined;
    const finalPath = try std.fmt.bufPrintZ(buf[0..], "{s}.png", .{path});
    try img.writeToFilePath(finalPath, .{ .png = .{} });

    std.debug.print("image created: {s}, w:{d}, h:{d}\n", .{ finalPath, width, height });
}
