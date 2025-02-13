const c = @import("cdefs.zig").c;

// TODO: Call this Assets, since now it's holding Fonts and probably other Raylib junk.
pub const Textures = struct {
    pub var Clouds: [5]c.Texture = undefined;
    pub var AlienBullet: c.Texture = undefined;

    pub var Invader1: c.Texture = undefined;

    pub var Canon: c.Texture = undefined;
    pub var LaserSm: c.Texture = undefined;
    pub var LaserMed: c.Texture = undefined;

    // Collision effects
    pub const Effects = struct {
        pub var Poof: c.Texture = undefined;
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
};
