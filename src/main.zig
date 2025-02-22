const std = @import("std");
const builtin = @import("builtin");
const state = @import("game_state.zig");
const conf = @import("conf.zig");
const zigimg = @import("zigimg");
const hive = @import("hive.zig");
const exp = @import("explosion.zig");
const res = @import("resources.zig");
const drw = @import("draw.zig");
const c = @import("cdefs.zig").c;

// NOTE: This magic selects which concrete allocator depending on build mode.
const GPA = std.heap.GeneralPurposeAllocator(.{ .safety = true });
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

    // const oop = @import("oop.zig");
    // try oop.testOop(alloc);

    //try regenAllBitmaps();

    c.SetConfigFlags(c.FLAG_VSYNC_HINT | c.FLAG_WINDOW_RESIZABLE);
    c.InitWindow(conf.WIN_WIDTH, conf.WIN_HEIGHT, "Cosmic Invaders");
    c.InitAudioDevice();
    //c.SetTargetFPS(60);
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
    //c.ClearBackground(c.WHITE);

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

fn drawLighteningStrike(fromX: i32, fromY: i32, toX: i32, toY: i32) void {
    const primaryColor = c.WHITE;
    const pixelSize = 2;
    const pixelVariationSize = 2;

    var currentX: i32 = fromX;
    var currentY: i32 = fromY;

    const end = c.Vector2{ .x = @floatFromInt(toX), .y = @floatFromInt(toY) };

    while (currentX != toX or currentY != toY) {
        var smallestDistance: f32 = 2000.00;
        var bestX: i32 = currentX;
        var bestY: i32 = currentY;

        // Generate possible pairs.
        for (0..4) |_| {
            const tmpX = c.GetRandomValue(currentX - pixelVariationSize, currentX + pixelVariationSize);
            const tmpY = c.GetRandomValue(currentY - pixelVariationSize, currentY + pixelVariationSize);

            const candidate = c.Vector2{ .x = @floatFromInt(tmpX), .y = @floatFromInt(tmpY) };
            const dist = c.Vector2Distance(candidate, end);

            if (dist < smallestDistance) {
                smallestDistance = dist;
                bestX = tmpX;
                bestY = tmpY;
            }
        }

        currentX = bestX;
        currentY = bestY;

        //c.DrawRectangle(currentX - pixelSize, currentY, pixelSize, pixelSize, c.BLUE);
        c.DrawRectangle(currentX, currentY, pixelSize, pixelSize, primaryColor);
        //c.DrawRectangle(currentX + pixelSize, currentY, pixelSize, pixelSize, c.BLUE);
    }

    // Draw start
    c.DrawRectangle(fromX - pixelSize, fromY, pixelSize, pixelSize, c.BLUE);
    c.DrawRectangle(fromX, fromY, pixelSize, pixelSize, primaryColor);
    c.DrawRectangle(fromX + pixelSize, fromY, pixelSize, pixelSize, c.BLUE);

    // Draw end
    c.DrawRectangle(toX - pixelSize, toY, pixelSize, pixelSize, c.BLUE);
    c.DrawRectangle(toX, toY, pixelSize, pixelSize, primaryColor);
    c.DrawRectangle(toX + toY, currentY, pixelSize, pixelSize, c.BLUE);
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
    const finalPath = try std.fmt.bufPrintZ(buf[0..], "{s}.png", .{path});
    try img.writeToFilePath(finalPath, .{ .png = .{} });

    std.debug.print("image created: {s}, w:{d}, h:{d}\n", .{ finalPath, width, height });
}
