const std = @import("std");
const hive = @import("hive.zig");
const proj = @import("projectile.zig");
const exp = @import("explosion.zig");
const cld = @import("cloud.zig");
const conf = @import("conf.zig");
const txtrs = @import("textures.zig");
const c = @import("cdefs.zig").c;

pub const GameState = struct {
    mTicks: usize = 0,

    mWave: usize = 0,

    mHive: hive.Hive = undefined,
    mClouds: std.ArrayList(cld.Cloud) = undefined,
    mEnemyProjectiles: std.ArrayList(proj.Projectile) = undefined,
    mPlayerProjectiles: std.ArrayList(proj.Projectile) = undefined,
    mInplaceExplosions: std.ArrayList(exp.Explosion) = undefined,

    const Self = @This();

    pub fn create(allocator: std.mem.Allocator) Self {
        return Self{
            .mHive = hive.Hive.create(allocator),
            .mClouds = std.ArrayList(cld.Cloud).init(allocator),
            .mEnemyProjectiles = std.ArrayList(proj.Projectile).init(allocator),
            .mPlayerProjectiles = std.ArrayList(proj.Projectile).init(allocator),
            .mInplaceExplosions = std.ArrayList(exp.Explosion).init(allocator),
        };
    }

    pub fn deinit(self: *Self) void {
        self.mHive.deinit();
        self.mClouds.deinit();
        self.mEnemyProjectiles.deinit();
        self.mPlayerProjectiles.deinit();
        self.mInplaceExplosions.deinit();
    }

    pub fn init(self: *Self) !void {
        // Create some clouds.
        for (0..conf.NumClouds) |_| {
            const cldIdx = c.GetRandomValue(0, txtrs.Textures.Clouds.len - 1);
            try self.mClouds.append(cld.Cloud.init(txtrs.Textures.Clouds[@intCast(cldIdx)]));
        }
        try self.mHive.init();
    }

    pub fn update(self: *Self) !void {
        // Clouds
        for (self.mClouds.items) |*cloud| {
            cloud.update();
        }

        // Hive
        try self.mHive.update();

        // Enemy projectiles
        var len = self.mEnemyProjectiles.items.len;
        while (len > 0) : (len -= 1) {
            var currProj = &self.mEnemyProjectiles.items[len - 1];
            currProj.update();
            if (currProj.mY >= conf.LAND_HEIGHT) {
                try self.createPoofExplosion(currProj.mX, currProj.mY);
                _ = self.mEnemyProjectiles.swapRemove(len - 1);
            }
        }

        // Explosions
        len = self.mInplaceExplosions.items.len;
        while (len > 0) : (len -= 1) {
            var currExp = &self.mInplaceExplosions.items[len - 1];
            try currExp.update();

            if (currExp.ended) {
                _ = self.mInplaceExplosions.swapRemove(len - 1);
            }
        }

        // Bump ticks.
        self.mTicks += 1;
    }

    pub fn createPoofExplosion(self: *Self, x: f32, y: f32) !void {
        try self.mInplaceExplosions.append(exp.Explosion.create(x, y, txtrs.Textures.Effects.Poof));
    }
};

pub var mGame: GameState = undefined;
