const std = @import("std");
const hive = @import("hive.zig");
const proj = @import("projectile.zig");

pub const GameState = struct {
    mTicks: usize = 0,
    mHive: hive.Hive = undefined,
    mEnemyProjectiles: std.ArrayList(proj.Projectile) = undefined,

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator) Self {
        return Self{
            .mHive = hive.Hive.init(allocator),
            .mEnemyProjectiles = std.ArrayList(proj.Projectile).init(allocator),
        };
    }

    pub fn deinit(self: *Self) void {
        self.mHive.deinit();
        self.mEnemyProjectiles.deinit();
    }
};

pub var mGame: GameState = undefined;
