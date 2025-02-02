const c = @import("cdefs.zig").c;

pub const Textures = struct {
    pub var Clouds: [5]c.Texture = undefined;
    pub var AlienBullet: c.Texture = undefined;

    // Collision effects
    pub const Effects = struct {
        pub var Poof: c.Texture = undefined;
    };
};
