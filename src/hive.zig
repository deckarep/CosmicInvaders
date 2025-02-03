const std = @import("std");
const state = @import("gamestate.zig");
const conf = @import("conf.zig");
const txtrs = @import("textures.zig");
const prj = @import("projectile.zig");
const c = @import("cdefs.zig").c;

pub const HiveBoundsMargin = 10;

pub const HiveState = enum {
    Scanning, // horizontal movement in either direction (left or right)
    Descending, // ticking closer to player
    Attack,
};

pub const Hive = struct {
    allocator: std.mem.Allocator,
    mInvaders: std.ArrayList(Invader) = undefined,
    mState: HiveState = .Scanning,

    mDirection: f32 = 1,
    mHorizontalSpeed: f32 = 1,
    mDescendingSpeed: f32 = 1,
    mDescendCountdown: i32 = conf.DescendCountdown,
    mAttackCountdown: i32 = conf.AttackCooldown,

    const Self = @This();

    pub fn create(allocator: std.mem.Allocator) Self {
        return Self{
            .allocator = allocator,
        };
    }

    pub fn init(self: *Self) !void {
        // Create the invaders.
        self.mInvaders = std.ArrayList(Invader).init(self.allocator);

        const xOffset = 40;
        const yOffset = 200;

        const invWidth = 16 * 2;
        const invHeight = 13 * 2;
        const invXPadding = 4;
        const invYPadding = 4;

        for (0..4) |y| {
            for (0..12) |x| {
                try self.mInvaders.append(Invader{
                    .mX = xOffset + ((invWidth + invXPadding) * @as(f32, @floatFromInt(x))),
                    .mY = yOffset + ((invHeight + invYPadding) * @as(f32, @floatFromInt(y))),
                });
            }
        }
    }

    pub fn deinit(self: *Self) void {
        self.mInvaders.deinit();
    }

    // TODO: some kind of functions to initialize the invader count.

    pub fn update(self: *Self) !void {
        //if (state.mGame.mTicks % 2 != 0) return;

        switch (self.mState) {
            .Scanning => {
                // Determine the bounds of the entire swarm.
                var minX: f32 = std.math.floatMax(f32);
                var maxX: f32 = -std.math.floatMin(f32);

                for (self.mInvaders.items) |*inv| {
                    if (inv.mX < minX) {
                        minX = inv.mX;
                    }
                    if (inv.mX > maxX) {
                        maxX = inv.mX;
                    }
                }

                // Check if moving the entire swarm would exceed boundaries.
                if (maxX + self.mHorizontalSpeed * self.mDirection > (conf.WIN_WIDTH - HiveBoundsMargin) or
                    (minX + self.mHorizontalSpeed * self.mDirection) < HiveBoundsMargin)
                {
                    self.mDescendCountdown = conf.DescendCountdown;
                    self.mState = .Descending;
                } else {
                    for (self.mInvaders.items) |*inv| {
                        inv.mX += self.mHorizontalSpeed * self.mDirection;
                    }
                }

                self.mAttackCountdown -= 1;

                if (self.mAttackCountdown <= 0) {
                    self.mState = .Attack;
                    self.mAttackCountdown = conf.AttackCooldown;
                }
            },
            .Descending => {
                var purgeOneOrMoreDead = false;
                for (self.mInvaders.items) |*inv| {
                    inv.mY += self.mDescendingSpeed;

                    if (inv.mY >= conf.LAND_HEIGHT) {
                        inv.dead = true;
                        purgeOneOrMoreDead = true;
                    }
                }

                // During the descent, one or more invaders died and need to be
                // purged from the hive. The hive does not tolerate death!
                if (purgeOneOrMoreDead) {
                    var len = self.mInvaders.items.len;
                    while (len != 0) : (len -= 1) {
                        const currInv = self.mInvaders.items[len - 1];
                        if (currInv.dead) {
                            // TODO: also show a -1 per invader to health.
                            try state.mGame.createPoofExplosion(currInv.mX, currInv.mY);
                            _ = self.mInvaders.swapRemove(len - 1);
                        }
                    }
                }

                self.mDescendCountdown -= 1;

                if (self.mDescendCountdown <= 0) {
                    self.mDirection *= -1;
                    self.mState = .Scanning;
                }
            },
            .Attack => {
                // Choose random invader to attack.
                const invTotal = self.mInvaders.items.len - 1;
                const randInvIdx: usize = @intCast(c.GetRandomValue(0, @intCast(invTotal)));
                const selectedInv = self.mInvaders.items[randInvIdx];
                try state.mGame.mEnemyProjectiles.append(prj.Projectile.create(selectedInv.mX, selectedInv.mY));

                self.mState = .Scanning;
            },
        }
    }
};

pub const Invader = struct {
    mX: f32 = 0,
    mY: f32 = 0,
    dead: bool = false,

    const Self = @This();
};
