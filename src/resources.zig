const std = @import("std");
const c = @import("cdefs.zig").c;

const ROOT_PATH = "data/";

// TODO: Call this Assets, since now it's holding Fonts and probably other Raylib junk.
pub const Resources = struct {
    pub var Background: c.Texture = undefined;
    pub var Clouds: [5]c.Texture = undefined;
    pub var AlienBullet: c.Texture = undefined;

    pub var Turret2: c.Texture = undefined;
    pub var Invader1: c.Texture = undefined;

    pub var Canon: c.Texture = undefined;
    pub var LaserSm: c.Texture = undefined;
    pub var LaserMed: c.Texture = undefined;

    // Collision effects
    pub const Effects = struct {
        pub var Poof: c.Texture = undefined;
        pub var Puff1: c.Texture = undefined;
        pub var Puff2: c.Texture = undefined;
    };

    // Game Fonts.
    pub const Fonts = struct {
        pub var Font1: c.Font = undefined;
    };

    pub const Sfx = struct {
        pub var LaserFire: c.Sound = undefined;
        pub var LaserHit: c.Sound = undefined;
    };

    pub const Music = struct {
        // TODO: cool music like, something with an authentic hip-hop beat.
        // like this! https://www.youtube.com/watch?v=oxxBXpnn2Jw
    };

    pub fn Load() !void {

        // Textures
        Resources.Background = c.LoadTexture(ROOT_PATH ++ "bg.mz.png");

        for (0..5) |i| {
            var buf: [32]u8 = undefined;
            const path = try std.fmt.bufPrintZ(
                buf[0..],
                "{s}cloud{d}.mz.png",
                .{ ROOT_PATH, i },
            );
            Resources.Clouds[i] = c.LoadTexture(path.ptr);
        }

        Resources.Invader1 = c.LoadTexture(ROOT_PATH ++ "invader1.sz.png");
        Resources.AlienBullet = c.LoadTexture(ROOT_PATH ++ "alienbullet.sz.png");
        Resources.Turret2 = c.LoadTexture(ROOT_PATH ++ "turret2.mz.png");

        Resources.Canon = c.LoadTexture(ROOT_PATH ++ "turret1.sz.png");
        Resources.LaserSm = c.LoadTexture(ROOT_PATH ++ "laser_small.mz.png");
        Resources.LaserMed = c.LoadTexture(ROOT_PATH ++ "laser_medium.mz.png");

        // Effects
        Resources.Effects.Poof = c.LoadTexture(ROOT_PATH ++ "poof.sz.png");
        Resources.Effects.Puff1 = c.LoadTexture(ROOT_PATH ++ "puff1.sz.png");
        Resources.Effects.Puff2 = c.LoadTexture(ROOT_PATH ++ "puff2.sz.png");

        // Fonts
        Resources.Fonts.Font1 = c.LoadFont(ROOT_PATH ++ "font_big_red_xna.png");

        // Sfx
        Resources.Sfx.LaserFire = c.LoadSound(ROOT_PATH ++ "zoop.wav");
        Resources.Sfx.LaserHit = c.LoadSound(ROOT_PATH ++ "laserhit.wav");
    }

    pub fn Unload() void {
        // Texture
        for (&Resources.Clouds) |*cloud| {
            c.UnloadTexture(cloud.*);
        }

        c.UnloadTexture(Resources.Turret2);
        c.UnloadTexture(Resources.Background);
        c.UnloadTexture(Resources.Invader1);
        c.UnloadTexture(Resources.Canon);
        c.UnloadTexture(Resources.LaserSm);
        c.UnloadTexture(Resources.LaserMed);
        c.UnloadTexture(Resources.AlienBullet);

        // Effects
        c.UnloadTexture(Resources.Effects.Poof);
        c.UnloadTexture(Resources.Effects.Puff1);
        c.UnloadTexture(Resources.Effects.Puff2);

        // Font
        c.UnloadFont(Resources.Fonts.Font1);

        // Sfx
        c.UnloadSound(Resources.Sfx.LaserFire);
        c.UnloadSound(Resources.Sfx.LaserHit);
    }
};
