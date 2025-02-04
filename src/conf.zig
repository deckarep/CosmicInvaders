const c = @import("cdefs.zig").c;

pub const WIN_WIDTH = 640;
pub const WIN_HEIGHT = 480;
pub const LAND_HEIGHT = 400;

pub const FontColor = struct {
    pub const Red = c.Color{ .r = 245, .g = 59, .b = 103, .a = 255 };
};

pub const HiveRespawnCooldown = 60 * 5;
pub const NumClouds = 6;
pub const DescendCountdown = 10;
pub const AttackCooldown = 60;

pub const EnemyProjectileYSpeed = 2;
