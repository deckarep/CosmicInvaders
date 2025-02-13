const std = @import("std");
const hive = @import("hive.zig");
const proj = @import("projectile.zig");
const pj = @import("proj.zig");
const exp = @import("explosion.zig");
const cld = @import("cloud.zig");
const conf = @import("conf.zig");
const res = @import("resources.zig");
const fls = @import("floating_scores.zig");
const bnnr = @import("wave_banner.zig");
const wp = @import("weapon_station.zig");
const c = @import("cdefs.zig").c;

pub const GameState = struct {
    mAllocator: std.mem.Allocator,
    mTicks: usize = 0,
    mWave: usize = 0,

    mWaveBanner: bnnr.WaveBanner = undefined,
    mHive: hive.Hive = undefined,
    mHiveCooldown: usize = conf.HiveRespawnCooldown,
    mClouds: std.ArrayList(cld.Cloud) = undefined,
    mFloatingScores: std.ArrayList(fls.FloatingScore) = undefined,
    mEnemyProjectiles: std.ArrayList(proj.Projectile) = undefined,
    mPlayerProjectiles: std.ArrayList(pj.Proj) = undefined,
    mInplaceExplosions: std.ArrayList(exp.Explosion) = undefined,
    mWeaponStations: std.ArrayList(wp.WeaponStation) = undefined,

    const Self = @This();

    pub fn create(allocator: std.mem.Allocator) Self {
        return Self{
            .mAllocator = allocator,
            .mWaveBanner = bnnr.WaveBanner.create(0),
            .mHive = hive.Hive.create(allocator),
            .mClouds = std.ArrayList(cld.Cloud).init(allocator),
            .mEnemyProjectiles = std.ArrayList(proj.Projectile).init(allocator),
            .mPlayerProjectiles = std.ArrayList(pj.Proj).init(allocator),
            .mInplaceExplosions = std.ArrayList(exp.Explosion).init(allocator),
            .mFloatingScores = std.ArrayList(fls.FloatingScore).init(allocator),
            .mWeaponStations = std.ArrayList(wp.WeaponStation).init(allocator),
        };
    }

    pub fn deinit(self: *Self) void {
        self.mHive.deinit();
        self.mClouds.deinit();
        self.mEnemyProjectiles.deinit();

        // Heap allocated.
        for (self.mPlayerProjectiles.items) |p| {
            p.deinit();
        }
        self.mPlayerProjectiles.deinit();

        self.mInplaceExplosions.deinit();
        self.mFloatingScores.deinit();
        self.mWeaponStations.deinit();
    }

    pub fn init(self: *Self) !void {
        // Create some clouds.
        for (0..conf.NumClouds) |_| {
            const cldIdx = c.GetRandomValue(0, res.Resources.Clouds.len - 1);
            try self.mClouds.append(cld.Cloud.init(res.Resources.Clouds[@intCast(cldIdx)]));
        }
        try self.mHive.init();

        try self.mWaveBanner.showWave(self.mWave);

        // For now just create a single weapon to start with.
        try self.mWeaponStations.append(wp.WeaponStation.create(wp.WeaponStationKind.Canon));
    }

    pub fn update(self: *Self) !void {
        // Clouds
        for (self.mClouds.items) |*cloud| {
            cloud.update();
        }

        // Hive (as a whole)
        try self.mHive.update();
        if (self.mHive.dead()) {
            // The -5 is for a little wait time before we show the wave banner.
            if (self.mHiveCooldown == (conf.HiveRespawnCooldown - 5)) {
                // Bump the wave count, show the banner.
                // NOTE: This is started on a single cycle.
                try self.mWaveBanner.showWave(self.mWave);
                self.mWave += 1;
            }
            self.mHiveCooldown -= 1;
            if (self.mHiveCooldown <= 0) {
                try self.mHive.respawn();
                self.mHiveCooldown = conf.HiveRespawnCooldown;
            }
        }

        // Invaders
        for (self.mHive.mInvaders.items) |*inv| {
            inv.update();
        }

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

        // Player projectiles
        len = self.mPlayerProjectiles.items.len;
        while (len > 0) : (len -= 1) {
            var currProj = self.mPlayerProjectiles.items[len - 1];
            // 1. Update projectile.
            try currProj.update();

            // 2. Check on collision.
            const projBounds = currProj.getBounds();
            const hb = self.mHive.getBounds();

            // 2.a First check if colliding with hive in order to skip checking
            // projectiles blatantly out of range.
            if (c.CheckCollisionRecs(projBounds, hb)) {
                // 2.b Find out which invader was hit.
                var anyDead = false;
                for (self.mHive.mInvaders.items) |*inv| {
                    if (inv.checkHit(projBounds)) {
                        c.PlaySound(res.Resources.Sfx.LaserHit);
                        currProj.markDead();
                    }
                    if (inv.dead()) {
                        anyDead = true;
                    }
                }
                if (anyDead) {
                    // 2.c Mark this projectile as dead and cull dead invaders.
                    try self.mHive.cullInvaders();
                }
            }

            // 3. Check on dead (ground hit, out of bounds or marked from above code)
            if (currProj.isDead()) {
                currProj.deinit();
                _ = self.mPlayerProjectiles.swapRemove(len - 1);
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

        // Floating Scores
        len = self.mFloatingScores.items.len;
        while (len > 0) : (len -= 1) {
            var currScore = &self.mFloatingScores.items[len - 1];
            currScore.update();

            if (currScore.ended()) {
                _ = self.mFloatingScores.swapRemove(len - 1);
            }
        }

        // Weapon Stations
        for (self.mWeaponStations.items) |*station| {
            try station.update();
        }

        // Wave Banner
        try self.mWaveBanner.update();

        // Bump ticks.
        self.mTicks += 1;
    }

    pub fn draw(self: Self) !void {
        // Weapon Stations
        for (self.mWeaponStations.items) |*station| {
            try station.draw();
        }

        // Invaders
        for (self.mHive.mInvaders.items) |*inv| {
            inv.draw();
        }

        // Player projectiles
        for (self.mPlayerProjectiles.items) |p| {
            try p.draw();
        }

        const hb = self.mHive.getBounds();
        if (hb.x >= 0 and hb.y >= 0 and hb.width >= 0 and hb.height >= 0) {
            c.DrawRectangleLines(
                @intFromFloat(hb.x),
                @intFromFloat(hb.y),
                @intFromFloat(hb.width),
                @intFromFloat(hb.height),
                c.YELLOW,
            );
        }
    }

    pub fn createPoofExplosion(self: *Self, x: f32, y: f32) !void {
        try self.mInplaceExplosions.append(exp.Explosion.create(x, y, res.Resources.Effects.Poof));
    }

    pub fn createMiniRedFloatingScore(self: *Self, text: [:0]const u8, x: f32, y: f32) !void {
        try self.mFloatingScores.append(fls.FloatingScore.create(
            text,
            x,
            y,
            fls.ScoreStyle.MiniRed,
        ));
    }

    pub fn createSmallWhiteFloatingScore(self: *Self, text: [:0]const u8, x: f32, y: f32) !void {
        try self.mFloatingScores.append(fls.FloatingScore.create(
            text,
            x,
            y,
            fls.ScoreStyle.SmallWhite,
        ));
    }

    pub fn spawnCanonBullet(self: *Self, x: f32, y: f32) !void {
        const cBullet = try pj.CanonBullet.create(x, y, self.mAllocator);
        const p = cBullet.asProjectile();
        try self.mPlayerProjectiles.append(p);
    }
};

pub var mGame: GameState = undefined;
