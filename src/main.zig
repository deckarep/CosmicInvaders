const std = @import("std");
const builtin = @import("builtin");
const state = @import("game_state.zig");
const conf = @import("conf.zig");
const zigimg = @import("zigimg");
const hive = @import("hive.zig");
const exp = @import("explosion.zig");
const res = @import("resources.zig");
const drw = @import("draw.zig");
const c = @import("c");

// NOTE: This magic selects which concrete allocator depending on build mode.
const GPA = std.heap.DebugAllocator(.{ .safety = true });
var gpa: ?GPA = gpaBreak: {
    if (builtin.link_libc) {
        if (switch (builtin.mode) {
            .ReleaseSafe, .ReleaseFast => true,

            // We also use it if we can detect we're running under
            // Valgrind since Valgrind only instruments the C allocator
            else => std.valgrind.runningOnValgrind() > 0,
        }) break :gpaBreak null;
    }

    break :gpaBreak GPA{};
};
var alloc: std.mem.Allocator = undefined;

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

fn inShakeScope() void {
    c.rlPushMatrix();
    const time: f32 = @floatFromInt(state.mGame.mTicks);
    const shakeOffsetX = @cos(time * 50.0) * state.mGame.mShakeIntensity;
    const shakeOffsetY = @sin(time * 50.0) * state.mGame.mShakeIntensity;
    c.rlTranslatef(shakeOffsetX, shakeOffsetY, 0);
}

fn outShakeScope() void {
    c.rlPopMatrix();
    state.mGame.mShakeIntensity *= conf.DECAY_SHAKE_INTENSITY;
}

pub fn main() !void {
    // Prints to stderr (it's a shortcut based on `std.io.getStdErr()`)
    std.debug.print("All your {s} are belong to us.\n", .{"codebase"});

    // Set the allocator interface to whatever concrete allocator was selected above.
    if (gpa) |*value| {
        std.debug.print("Using the GPA (Debug allocator)...\n", .{});
        alloc = value.allocator();
    } else {
        std.debug.print("Using the c_allocator...\n", .{});
        alloc = std.heap.c_allocator;
    }

    defer if (gpa) |*myGPA| {
        const deinit_status = myGPA.deinit();
        if (deinit_status == .leak) {
            std.debug.print("You lack discipline! Leaks detected!\n", .{});
        }
    };

    try testAlignment(alloc);

    // const oop = @import("oop.zig");
    // try oop.testOop(alloc);

    //try regenAllBitmaps();

    c.SetConfigFlags(c.FLAG_WINDOW_RESIZABLE); //| c.FLAG_VSYNC_HINT);
    c.InitWindow(conf.WIN_WIDTH, conf.WIN_HEIGHT, "Cosmic Invaders - @deckarep");
    c.InitAudioDevice();
    c.SetTargetFPS(60);
    defer c.CloseWindow();
    defer c.CloseAudioDevice();

    try res.Resources.Load();
    defer res.Resources.Unload();

    state.mGame = state.GameState.create(alloc);
    try state.mGame.init();
    defer state.mGame.deinit();

    while (!c.WindowShouldClose()) {
        try update();
        try draw();
    }
}

// testAlignment has nothing to do with this game, but I was curious if alignment affects every field or just the starting address.
// It affects just the starting address.
fn testAlignment(a: std.mem.Allocator) !void {
    var regularList: std.ArrayList(f32) = .empty;
    defer regularList.deinit(a);
    try regularList.append(a, 11);
    try regularList.append(a, 22);
    try regularList.append(a, 33);
    try regularList.append(a, 44);
    try regularList.append(a, 55);

    for (regularList.items) |*item| {
        std.debug.print("regularList: val({d})=>ptr({p})\n", .{ item.*, item });
    }

    var alignedList: std.array_list.Aligned(f32, std.mem.Alignment.@"64") = .empty;
    defer alignedList.deinit(a);
    try alignedList.append(a, 111);
    try alignedList.append(a, 222);
    try alignedList.append(a, 333);
    try alignedList.append(a, 444);
    try alignedList.append(a, 555);

    for (alignedList.items) |*item| {
        std.debug.print("alignedList: val({d})=>ptr({p})\n", .{ item.*, item });
    }
}

fn update() !void {
    if (c.IsMouseButtonReleased(c.MOUSE_BUTTON_RIGHT)) {
        try state.mGame.debugCreateRandomWeaponStation();
    }
    try state.mGame.update();
}

fn draw() !void {
    c.BeginDrawing();
    defer c.EndDrawing();

    // Since we always redraw the screen this is not-needed and it helps avoid
    // little white edges occurring on screen shake!
    // c.ClearBackground(c.WHITE);

    const isShaking = state.mGame.mShakeIntensity > 0.01;
    if (isShaking) {
        inShakeScope();
    }

    // Anything drawn in here, will shake.
    try state.mGame.draw();

    defer if (isShaking) {
        outShakeScope();
    };

    c.DrawRectangle(0, conf.LAND_HEIGHT, conf.WIN_WIDTH, 2, c.YELLOW);
    c.DrawRectangle(8, conf.WIN_HEIGHT - 20, 80, 40, c.BLACK);
    c.DrawFPS(10, conf.WIN_HEIGHT - 20);
}

fn regenAllBitmaps() !void {
    for (mzFiles) |path| {
        try genBitmapFile(path, alloc);
    }
}

fn genBitmapFile(path: [:0]const u8, allocator: std.mem.Allocator) !void {
    const f = c.gzopen(path, "rb");
    defer _ = c.gzclose(f);

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

            // Just render fonts how they originally were designed!
            //if (!std.mem.startsWith(u8, path, "data/font_")) {

            // Check for KeyOut colors
            if (color24Eq(color, KeyOutHotPink) or
                (color24Eq(color, KeyOutFontBlue) and std.mem.startsWith(u8, path, "data/font_")))
            {
                a = 0; // Knock out color by setting alpha to 0
            }
            //}

            // Ensure we index correctly within bounds
            const index = (y * @as(usize, @intCast(height))) + x;
            img.pixels.rgba32[index] = zigimg.color.Rgba32.initRgba(r, g, b, a);
        }
    }

    var buf: [32]u8 = undefined;
    const finalPath = try std.fmt.bufPrintSentinel(buf[0..], "{s}.png", .{path}, 0);
    try img.writeToFilePath(finalPath, .{ .png = .{} });

    std.debug.print("image created: {s}, w:{d}, h:{d}\n", .{ finalPath, width, height });
}
