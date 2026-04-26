const std = @import("std");
const set = @import("ziglangSet");
const state = @import("game_state.zig");
const conf = @import("conf.zig");
const res = @import("resources.zig");
const pj = @import("projectile.zig");
const drw = @import("draw.zig");
const esngs = @import("easings.zig");
const inv = @import("invader.zig");
const c = @import("c");

pub const HiveBoundsMargin = 10;

pub const HiveState = enum {
    Scanning, // horizontal movement in either direction (left or right)
    Descending, // ticking closer to player1
    Attack,
    Swapping, // A test, a state where they will periodically swap around using easing funcs.
};

pub const InvaderSwaps = struct {
    a: ?*inv.Invader = undefined,
    aX: f32 = 0,
    aY: f32 = 0,

    b: ?*inv.Invader = undefined,
    bX: f32 = 0,
    bY: f32 = 0,
};

pub const Hive = struct {
    mAllocator: std.mem.Allocator,
    mInvaders: std.ArrayList(inv.Invader) = undefined,
    mActiveInvaders: set.Set(usize) = undefined,
    mState: HiveState = .Scanning,
    mRows: usize = 1,

    mDirection: f32 = 1,
    mHorizontalSpeed: f32 = conf.HiveHorizontalSpeed,
    mDescendingSpeed: f32 = conf.HiveDescendSpeed,
    mDescendCountdown: i32 = conf.DescendCountdown,
    mAttackCountdown: i32 = conf.AttackCooldown,
    mSwapCountdown: i32 = conf.SwapCooldown,
    mStateFrames: usize = 0,

    mInvaderSwaps: InvaderSwaps = .{},

    const Self = @This();

    pub fn create(allocator: std.mem.Allocator) Self {
        return Self{
            .mAllocator = allocator,
        };
    }

    pub fn init(self: *Self) !void {
        // Create the empty invaders list.
        self.mInvaders = .empty;
        self.mActiveInvaders = .empty;
    }

    // TODO: some kind of functions to initialize the invader count, and rows.
    pub fn respawn(self: *Self) !void {
        self.mState = .Scanning;

        const xOffset = 40;
        const yOffset = 0; //350;

        const invXPadding = 4;
        const invYPadding = 4;

        for (0..self.mRows) |y| {
            for (0..12) |x| {
                const invID = inv.newID();
                try self.mInvaders.append(self.mAllocator, inv.Invader{
                    .mID = invID,
                    .mX = xOffset + ((inv.InvWidth + invXPadding) * @as(f32, @floatFromInt(x))),
                    .mY = yOffset + ((inv.InvHeight + invYPadding) * @as(f32, @floatFromInt(y))),
                });

                // track active invaders!
                _ = try self.mActiveInvaders.add(self.mAllocator, invID);
            }
        }

        // Whenever respawn is invoked, we increase the difficulty,
        // for now bump invader rows.
        self.mRows += 1;
    }

    pub fn deinit(self: *Self) void {
        self.mInvaders.deinit(self.mAllocator);
        self.mActiveInvaders.deinit(self.mAllocator);
    }

    pub inline fn dead(self: Self) bool {
        return self.mInvaders.items.len == 0;
    }

    fn chooseTwoInvaders(self: *Self) void {
        const last_idx = self.mInvaders.items.len - 1;

        const a_idx: usize = @intCast(c.GetRandomValue(0, @intCast(last_idx)));

        // Find another invader that is not the same one, so a swap can occur.
        var b_idx = a_idx;
        while (b_idx == a_idx) {
            b_idx = @intCast(c.GetRandomValue(0, @intCast(last_idx)));
        }

        self.mInvaderSwaps.a = &self.mInvaders.items[a_idx];
        self.mInvaderSwaps.aX = self.mInvaderSwaps.a.?.mX;
        self.mInvaderSwaps.aY = self.mInvaderSwaps.a.?.mY;

        self.mInvaderSwaps.b = &self.mInvaders.items[b_idx];
        self.mInvaderSwaps.bX = self.mInvaderSwaps.b.?.mX;
        self.mInvaderSwaps.bY = self.mInvaderSwaps.b.?.mY;
    }

    pub fn cullInvaders(self: *Self) !void {
        var howMany: usize = 0;
        var len = self.mInvaders.items.len;
        while (len != 0) : (len -= 1) {
            const currInv = self.mInvaders.items[len - 1];
            if (currInv.dead()) {
                // When invader is dead, spawn a poof explosion as well as a -1 red mini score.
                try state.mGame.spawnPoofExplosion(currInv.mX, currInv.mY);

                switch (currInv.mDeathReason.?) {
                    .HitGround => {
                        std.debug.print("culling invader id:{d} due to hitting ground\n", .{currInv.mID});
                        try state.mGame.spawnMiniRedFloatingScore("-1", currInv.mX, currInv.mY);
                        state.mGame.beginShake();
                    },
                    .HitWeaponStation => {
                        std.debug.print("culling invader id:{d} due to hitting a weapon station\n", .{currInv.mID});
                        try state.mGame.spawnMiniRedFloatingScore("-10", currInv.mX, currInv.mY);
                        state.mGame.beginShake();
                    },
                    .PlayerProjectile => {
                        std.debug.print("culling invader id:{d} due to player projectile\n", .{currInv.mID});
                        try state.mGame.spawnSmallWhiteFloatingScore("+20", currInv.mX, currInv.mY);
                    },
                }

                _ = self.mInvaders.swapRemove(len - 1);
                _ = self.mActiveInvaders.remove(currInv.mID);
                howMany += 1;
            }
        }

        std.debug.print("culled {d} invaders\n", .{howMany});
    }

    fn pumpFrames(self: *Self, dur: usize, targetState: HiveState) bool {
        if (self.mStateFrames >= dur) {
            self.mStateFrames = 0;
            self.mState = targetState;
            return true;
        }
        self.mStateFrames += 1;
        return false;
    }

    pub fn getBounds(self: Self) c.Rectangle {

        // Determine the bounds of the entire swarm.
        var minX: f32 = std.math.floatMax(f32);
        var maxX: f32 = -std.math.floatMin(f32);

        var minY: f32 = std.math.floatMax(f32);
        var maxY: f32 = -std.math.floatMin(f32);

        for (self.mInvaders.items) |*in| {
            // Capture x-axis bounds.
            if (in.mX < minX) {
                minX = in.mX;
            }
            // NOTE: the right side of the bounds should also include the width of the invader.
            if (in.mX + inv.InvWidth > maxX) {
                maxX = in.mX + inv.InvWidth;
            }

            // Capture y-axis bounds.
            if (in.mY < minY) {
                minY = in.mY;
            }
            // NOTE: the right side of the bounds should also include the height of the invader.
            if (in.mY + inv.InvHeight > maxY) {
                maxY = in.mY + inv.InvHeight;
            }
        }

        return .{
            .x = minX,
            .y = minY,
            .width = maxX - minX,
            .height = maxY - minY,
        };
    }

    pub fn getRandomInvader(self: Self) ?*inv.Invader {
        if (self.mInvaders.items.len > 0) {
            const invIdx = c.GetRandomValue(0, self.mInvaders.items.len - 1);
            return &self.mInvaders.items[@intCast(invIdx)];
        }

        return null;
    }

    pub fn checkInvaderCollided(self: *Self, invader: *inv.Invader) bool {
        _ = self;

        // NOTE: kinda weird that this function is grabbing a reference to mWeaponStations directly.
        const invBounds = invader.getBounds();

        // 1. Check if weapon station was hit.
        for (state.mGame.mWeaponStations.items) |*ws| {
            // When the weapon station was hit, it takes damage.
            if (ws.checkHit(invBounds, 10)) {
                // And the invader dies.
                invader.mDeathReason = .HitWeaponStation;
                return true;
            }
        }

        // 2. Check if land was hit.
        if (invBounds.y + invBounds.height >= conf.LAND_HEIGHT) {
            invader.mDeathReason = .HitGround;
            return true;
        }

        return false;
    }

    pub fn update(self: *Self) !void {
        //if (state.mGame.mTicks % 2 != 0) return;
        if (self.mInvaders.items.len == 0) {
            // TODO: Hive must have been wiped out, spawn a new wave.
            return;
        }

        if (c.IsKeyDown(c.KEY_LEFT_SHIFT)) {
            self.mHorizontalSpeed = 5;
            self.mDescendingSpeed = 5;
        } else {
            self.mHorizontalSpeed = conf.HiveHorizontalSpeed;
            self.mDescendingSpeed = conf.HiveDescendSpeed;
        }

        var purgeOneOrMoreDead = false;

        switch (self.mState) {
            .Scanning => {
                // Determine the bounds of the entire swarm.
                const hb = self.getBounds();

                // Check if moving the entire swarm would exceed boundaries.
                if ((hb.x + hb.width) + self.mHorizontalSpeed * self.mDirection > (conf.WIN_WIDTH - HiveBoundsMargin) or
                    (hb.x + self.mHorizontalSpeed * self.mDirection) < HiveBoundsMargin)
                {
                    self.mDescendCountdown = conf.DescendCountdown;
                    self.mState = .Descending;
                } else {
                    for (self.mInvaders.items) |*in| {
                        in.mX += self.mHorizontalSpeed * self.mDirection;

                        // Check on any collisions for this invader.
                        if (self.checkInvaderCollided(in)) {
                            purgeOneOrMoreDead = true;
                        }
                    }
                }

                // Bump attack countdown.
                self.mAttackCountdown -= 1;
                if (self.mAttackCountdown <= 0) {
                    self.mState = .Attack;
                    self.mAttackCountdown = conf.AttackCooldown;
                }

                // When enabled, do the swap but only if at least 2 invaders are still alive.
                if (conf.SwapEnabled and self.mInvaders.items.len > 1) {
                    self.mSwapCountdown -= 1;
                    if (self.mSwapCountdown <= 0) {
                        self.chooseTwoInvaders();
                        self.mState = .Swapping;
                        self.mSwapCountdown = conf.SwapCooldown;
                    }
                }
            },
            .Descending => {
                for (self.mInvaders.items) |*in| {
                    in.mY += self.mDescendingSpeed;

                    // Check on any collisions for this invader.
                    if (self.checkInvaderCollided(in)) {
                        purgeOneOrMoreDead = true;
                    }
                }

                self.mDescendCountdown -= 1;
                if (self.mDescendCountdown <= 0) {
                    self.mDirection *= -1;
                    self.mState = .Scanning;
                }
            },
            .Swapping => {
                const is = &self.mInvaderSwaps;
                const invA = self.mInvaderSwaps.a.?;
                const invB = self.mInvaderSwaps.b.?;

                const easeFn = esngs.easeInOutCubic;

                // Move Invader A
                invA.mX = easeFn(
                    @floatFromInt(self.mStateFrames),
                    is.aX,
                    is.bX - is.aX,
                    @floatFromInt(30),
                );
                invA.mY = easeFn(
                    @floatFromInt(self.mStateFrames),
                    is.aY,
                    is.bY - is.aY,
                    @floatFromInt(30),
                );

                // Move Invader B
                invB.mX = easeFn(
                    @floatFromInt(self.mStateFrames),
                    is.bX,
                    is.aX - is.bX,
                    @floatFromInt(30),
                );
                invB.mY = easeFn(
                    @floatFromInt(self.mStateFrames),
                    is.bY,
                    is.aY - is.bY,
                    @floatFromInt(30),
                );

                if (self.pumpFrames(30, .Scanning)) {
                    is.a = null;
                    is.b = null;
                }
            },
            .Attack => {
                // Choose random invader to attack.
                const invTotal = self.mInvaders.items.len - 1;
                const randInvIdx: usize = @intCast(c.GetRandomValue(0, @intCast(invTotal)));
                const selectedInv = self.mInvaders.items[randInvIdx];
                const p = try pj.AlienBullet.create(selectedInv.mX, selectedInv.mY, self.mAllocator);
                const bullet = p.asProjectile();
                try state.mGame.mEnemyProjectiles.append(self.mAllocator, bullet);

                self.mState = .Scanning;
            },
        }

        // If one or more invaders died and need to be
        // purged from the hive. The hive does not tolerate insolance, purge the invader.
        if (purgeOneOrMoreDead) {
            try self.cullInvaders();
        }
    }
};
