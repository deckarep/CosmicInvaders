const conf = @import("conf.zig");

pub const Projectile = struct {
    mX: i32 = 0,
    mY: i32 = 0,

    const Self = @This();

    pub fn update(self: *Self) void {
        self.mY += conf.EnemyProjectileYSpeed;
    }
};
