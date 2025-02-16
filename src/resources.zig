const c = @import("cdefs.zig").c;

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

    pub fn Load() void {
        Resources.Background = c.LoadTexture("data/bg.mz.png");
        Resources.Turret2 = c.LoadTexture("data/turret2.mz.png");

        // Textures
        Resources.Clouds[0] = c.LoadTexture("data/cloud1.mz.png");
        Resources.Clouds[1] = c.LoadTexture("data/cloud2.mz.png");
        Resources.Clouds[2] = c.LoadTexture("data/cloud3.mz.png");
        Resources.Clouds[3] = c.LoadTexture("data/cloud4.mz.png");
        Resources.Clouds[4] = c.LoadTexture("data/cloud5.mz.png");

        Resources.Invader1 = c.LoadTexture("data/invader1.sz.png");

        Resources.Canon = c.LoadTexture("data/turret1.sz.png");
        Resources.LaserSm = c.LoadTexture("data/laser_small.mz.png");
        Resources.LaserMed = c.LoadTexture("data/laser_medium.mz.png");
        Resources.AlienBullet = c.LoadTexture("data/alienbullet.sz.png");

        // Effects
        Resources.Effects.Poof = c.LoadTexture("data/poof.sz.png");
        Resources.Effects.Puff1 = c.LoadTexture("data/puff1.sz.png");
        Resources.Effects.Puff2 = c.LoadTexture("data/puff2.sz.png");

        // Fonts
        Resources.Fonts.Font1 = c.LoadFont("data/font_big_red_xna.png");

        // Sfx
        Resources.Sfx.LaserFire = c.LoadSound("data/zoop.wav");
        Resources.Sfx.LaserHit = c.LoadSound("data/laserhit.wav");
    }

    pub fn Unload() void {
        // Texture
        for (Resources.Clouds) |cloud| {
            c.UnloadTexture(cloud);
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
