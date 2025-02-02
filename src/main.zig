const std = @import("std");
const state = @import("gamestate.zig");
const conf = @import("conf.zig");
const zigimg = @import("zigimg");
const hive = @import("hive.zig");
const txtrs = @import("textures.zig");
const c = @import("cdefs.zig").c;

// Window includes monitor.

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

var background: c.Texture = undefined;
var invader1: c.Texture = undefined;
var turret2: c.Texture = undefined;

pub fn main() !void {
    // Prints to stderr (it's a shortcut based on `std.io.getStdErr()`)
    std.debug.print("All your {s} are belong to us.\n", .{"codebase"});

    //try regenAllBitmaps();

    c.SetConfigFlags(c.FLAG_VSYNC_HINT | c.FLAG_WINDOW_RESIZABLE);
    c.InitWindow(conf.WIN_WIDTH, conf.WIN_HEIGHT, "Cosmic Invaders");
    c.InitAudioDevice();
    c.SetTargetFPS(60);
    defer c.CloseWindow();

    try loadAssets();
    defer unloadAssets();

    state.mGame = state.GameState.create(alloc);
    try state.mGame.init();
    defer state.mGame.deinit();

    while (!c.WindowShouldClose()) {
        try update();
        try draw();
    }
}

fn loadAssets() !void {
    txtrs.Textures.Clouds[0] = c.LoadTexture("data/cloud1.mz.png");
    txtrs.Textures.Clouds[1] = c.LoadTexture("data/cloud2.mz.png");
    txtrs.Textures.Clouds[2] = c.LoadTexture("data/cloud3.mz.png");
    txtrs.Textures.Clouds[3] = c.LoadTexture("data/cloud4.mz.png");
    txtrs.Textures.Clouds[4] = c.LoadTexture("data/cloud5.mz.png");

    background = c.LoadTexture("data/bg.mz.png");
    invader1 = c.LoadTexture("data/invader1.sz.png");
    turret2 = c.LoadTexture("data/turret2.mz.png");
}

fn unloadAssets() void {
    for (txtrs.Textures.Clouds) |cloud| {
        c.UnloadTexture(cloud);
    }

    defer c.UnloadTexture(background);

    defer c.UnloadTexture(invader1);
    defer c.UnloadTexture(turret2);
}

fn update() !void {
    // Clouds
    for (state.mGame.mClouds.items) |*cloud| {
        cloud.update();
    }

    // Hive
    try state.mGame.mHive.update();

    // Enemy projectiles
    var len = state.mGame.mEnemyProjectiles.items.len;
    while (len > 0) : (len -= 1) {
        var currProj = &state.mGame.mEnemyProjectiles.items[len - 1];
        currProj.update();
        if (currProj.mY >= conf.WIN_HEIGHT) {
            _ = state.mGame.mEnemyProjectiles.swapRemove(len - 1);
        }
    }

    // Bump ticks.
    state.mGame.mTicks += 1;
}

fn draw() !void {
    c.BeginDrawing();
    defer c.EndDrawing();

    c.ClearBackground(c.WHITE);

    // Draw background.
    var view = c.Rectangle{ .x = 0, .y = 0, .width = 320, .height = 240 };
    drawTextureScaled(0, 0, background, view, 2.0);

    // Draw clouds.
    for (state.mGame.mClouds.items) |*cloud| {
        cloud.draw();
    }

    // Invaders
    for (state.mGame.mHive.mInvaders.items, 0..) |inv, idx| {
        const width = 16;
        const height = 13;
        const frameSeqCount = 6;
        const halfFrameSeqCount = frameSeqCount / 2;
        const speedReduceFactor = 10;
        // Division is used to slow the ticks down a bit.
        // Using ticks as a stream of numbers, generates 0-5 inclusive
        // Using the idx, causes the animations to offset by idx number.
        const phase = (((state.mGame.mTicks) / speedReduceFactor) + idx) % frameSeqCount;
        // Then the upper half of the numbers are subtracted from 6, to create a
        // repeating pattern that goes up and down in sequence.
        const value = if (phase > halfFrameSeqCount) frameSeqCount - phase else phase;
        const xOffset: f32 = @floatFromInt(value * width);
        const yOffset: f32 = @floatFromInt(height * 0);
        view = c.Rectangle{ .x = xOffset, .y = yOffset, .width = width, .height = height };
        drawTextureScaled(@intFromFloat(inv.mX), @intFromFloat(inv.mY), invader1, view, 2.0);
    }

    // Enemy projectiles
    for (state.mGame.mEnemyProjectiles.items) |prj| {
        c.DrawCircle(prj.mX, prj.mY, 4, c.RED);
    }

    // lightening strike
    drawLighteningStrike(10, 10, 300, 400);

    c.DrawRectangle(8, conf.WIN_HEIGHT - 20, 80, 40, c.BLACK);
    c.DrawFPS(10, conf.WIN_HEIGHT - 20);
}

fn drawLighteningStrike(fromX: i32, fromY: i32, toX: i32, toY: i32) void {
    const mainColor = c.WHITE;
    const pixelSize = 1;
    const pixelVariationSize = 1;

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

        c.DrawRectangle(currentX - pixelSize, currentY, pixelSize, pixelSize, c.BLUE);
        c.DrawRectangle(currentX, currentY, pixelSize, pixelSize, mainColor);
        c.DrawRectangle(currentX + pixelSize, currentY, pixelSize, pixelSize, c.BLUE);
    }

    // Draw start
    c.DrawRectangle(fromX - pixelSize, fromY, pixelSize, pixelSize, c.BLUE);
    c.DrawRectangle(fromX, fromY, pixelSize, pixelSize, mainColor);
    c.DrawRectangle(fromX + pixelSize, fromY, pixelSize, pixelSize, c.BLUE);

    // Draw end
    c.DrawRectangle(toX - pixelSize, toY, pixelSize, pixelSize, c.BLUE);
    c.DrawRectangle(toX, toY, pixelSize, pixelSize, mainColor);
    c.DrawRectangle(toX + toY, currentY, pixelSize, pixelSize, c.BLUE);
}

fn drawTextureScaled(x: i32, y: i32, texture: c.Texture, view: c.Rectangle, scale: f32) void {
    const src = c.Rectangle{
        .x = view.x,
        .y = view.y,
        .width = view.width,
        .height = view.height,
    };
    const dst = c.Rectangle{
        .x = @floatFromInt(x),
        .y = @floatFromInt(y),
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
