const c = @import("cdefs.zig").c;

// TODO: organize this crap into categories like Hive, vs Alien, vs WeaponStation, etc.

pub const SCALE_FACTOR = 2;
pub const WIN_WIDTH = 320 * SCALE_FACTOR;
pub const WIN_HEIGHT = 240 * SCALE_FACTOR;
pub const LAND_HEIGHT = 213 * SCALE_FACTOR;
pub const InitialShakeIntensity = 0.9;

pub const FontColor = struct {
    pub const Red = c.Color{
        .r = 245,
        .g = 59,
        .b = 103,
        .a = 255,
    };
};

pub const HiveHorizontalSpeed = 1;
pub const HiveDescendSpeed = 1;
pub const NumClouds = 6;
pub const DescendCountdown = 10;
pub const SwapEnabled = false;

pub const EnemyProjectileYSpeed = 2;

// Cooldowns
pub const AttackCooldown = 60;
pub const SwapCooldown = 120;
pub const HiveRespawnCooldown = 60 * 2;
pub const CanonCooldown = 300;
pub const TeslaCoilCooldown = 30;
pub const RocketLauncherCooldown = 240;
