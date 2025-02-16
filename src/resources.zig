const std = @import("std");
const c = @import("cdefs.zig").c;

const ROOT_PATH = "data/";

// TODO: Call this Assets, since now it's holding Fonts and probably other Raylib junk.
pub const Resources = struct {
    var texturesLoaded: usize = 0;
    var fontsLoaded: usize = 0;
    var soundsLoaded: usize = 0;

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
        pub var Explosion: c.Sound = undefined;
    };

    pub const Music = struct {
        // TODO: cool music like, something with an authentic hip-hop beat.
        // like this! https://www.youtube.com/watch?v=oxxBXpnn2Jw
    };

    pub fn Load() !void {

        // Textures
        Resources.Background = loadTexture(ROOT_PATH ++ "bg.mz.png");

        for (0..5) |i| {
            var buf: [32]u8 = undefined;
            const path = try std.fmt.bufPrintZ(
                buf[0..],
                "{s}cloud{d}.mz.png",
                .{ ROOT_PATH, i },
            );
            Resources.Clouds[i] = loadTexture(path);
        }

        Resources.Invader1 = loadTexture(ROOT_PATH ++ "invader1.sz.png");
        Resources.AlienBullet = loadTexture(ROOT_PATH ++ "alienbullet.sz.png");
        Resources.Turret2 = loadTexture(ROOT_PATH ++ "turret2.mz.png");

        Resources.Canon = loadTexture(ROOT_PATH ++ "turret1.sz.png");
        Resources.LaserSm = loadTexture(ROOT_PATH ++ "laser_small.mz.png");
        Resources.LaserMed = loadTexture(ROOT_PATH ++ "laser_medium.mz.png");

        // Effects
        Resources.Effects.Poof = loadTexture(ROOT_PATH ++ "poof.sz.png");
        Resources.Effects.Puff1 = loadTexture(ROOT_PATH ++ "puff1.sz.png");
        Resources.Effects.Puff2 = loadTexture(ROOT_PATH ++ "puff2.sz.png");

        // Fonts
        Resources.Fonts.Font1 = loadFont(ROOT_PATH ++ "font_big_red_xna.png");

        // Sfx
        Resources.Sfx.LaserFire = loadSound(ROOT_PATH ++ "zoop.wav");
        Resources.Sfx.LaserHit = loadSound(ROOT_PATH ++ "laserhit.wav");
        Resources.Sfx.Explosion = loadSound(ROOT_PATH ++ "boom1.wav");
    }

    fn loadTexture(path: [:0]const u8) c.Texture {
        Resources.texturesLoaded += 1;
        return c.LoadTexture(path.ptr);
    }

    fn unloadTexture(texture: c.Texture) void {
        Resources.texturesLoaded -= 1;
        c.UnloadTexture(texture);
    }

    fn loadSound(path: [:0]const u8) c.Sound {
        Resources.soundsLoaded += 1;
        return c.LoadSound(path.ptr);
    }

    fn unloadSound(snd: c.Sound) void {
        Resources.soundsLoaded -= 1;
        c.UnloadSound(snd);
    }

    fn loadFont(path: [:0]const u8) c.Font {
        Resources.fontsLoaded += 1;
        return c.LoadFont(path.ptr);
    }

    fn unloadFont(fnt: c.Font) void {
        Resources.fontsLoaded -= 1;
        c.UnloadFont(fnt);
    }

    pub fn Unload() void {
        defer {
            // Ensure we unloaded everything.
            // But, currently this doesn't tell us what is missing.
            std.debug.assert(Resources.texturesLoaded == 0);
            std.debug.assert(Resources.fontsLoaded == 0);
            std.debug.assert(Resources.soundsLoaded == 0);
        }

        // Texture
        for (&Resources.Clouds) |*cloud| {
            unloadTexture(cloud.*);
        }

        unloadTexture(Resources.Turret2);
        unloadTexture(Resources.Background);
        unloadTexture(Resources.Invader1);
        unloadTexture(Resources.Canon);
        unloadTexture(Resources.LaserSm);
        unloadTexture(Resources.LaserMed);
        unloadTexture(Resources.AlienBullet);

        // Effects
        unloadTexture(Resources.Effects.Poof);
        unloadTexture(Resources.Effects.Puff1);
        unloadTexture(Resources.Effects.Puff2);

        // Font
        unloadFont(Resources.Fonts.Font1);

        // Sfx
        unloadSound(Resources.Sfx.LaserFire);
        unloadSound(Resources.Sfx.LaserHit);
        unloadSound(Resources.Sfx.Explosion);
    }
};
