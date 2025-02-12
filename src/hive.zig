const std = @import("std");
const state = @import("gamestate.zig");
const conf = @import("conf.zig");
const txtrs = @import("textures.zig");
const prj = @import("projectile.zig");
const esngs = @import("easings.zig");
const c = @import("cdefs.zig").c;

const invWidth = 16 * 2;
const invHeight = 13 * 2;

pub const HiveBoundsMargin = 10;

pub const HiveState = enum {
    Scanning, // horizontal movement in either direction (left or right)
    Descending, // ticking closer to player1
    Attack,
    Swapping, // A test, a state where they will periodically swap around using easing funcs.
};

pub const InvaderSwaps = struct {
    a: ?*Invader = undefined,
    aX: f32 = 0,
    aY: f32 = 0,

    b: ?*Invader = undefined,
    bX: f32 = 0,
    bY: f32 = 0,
};

pub const Hive = struct {
    allocator: std.mem.Allocator,
    mInvaders: std.ArrayList(Invader) = undefined,
    mState: HiveState = .Scanning,
    mRows: usize = 1,

    mDirection: f32 = 1,
    mHorizontalSpeed: f32 = 1,
    mDescendingSpeed: f32 = 1,
    mDescendCountdown: i32 = conf.DescendCountdown,
    mAttackCountdown: i32 = conf.AttackCooldown,
    mSwapCountdown: i32 = conf.SwapCooldown,
    mStateFrames: usize = 0,

    mInvaderSwaps: InvaderSwaps = .{},

    const Self = @This();

    pub fn create(allocator: std.mem.Allocator) Self {
        return Self{
            .allocator = allocator,
        };
    }

    pub fn init(self: *Self) !void {
        // Create the invaders.
        self.mInvaders = std.ArrayList(Invader).init(self.allocator);
    }

    // TODO: some kind of functions to initialize the invader count, and rows.
    pub fn respawn(self: *Self) !void {
        self.mState = .Scanning;

        const xOffset = 40;
        const yOffset = 300;

        const invXPadding = 4;
        const invYPadding = 4;

        for (0..self.mRows) |y| {
            for (0..12) |x| {
                try self.mInvaders.append(Invader{
                    .mX = xOffset + ((invWidth + invXPadding) * @as(f32, @floatFromInt(x))),
                    .mY = yOffset + ((invHeight + invYPadding) * @as(f32, @floatFromInt(y))),
                });
            }
        }

        // Whenever respawn is invoked, we increase the difficulty,
        // for now bump invader rows.
        self.mRows += 1;
    }

    pub fn deinit(self: *Self) void {
        self.mInvaders.deinit();
    }

    pub inline fn dead(self: Self) bool {
        return self.mInvaders.items.len == 0;
    }

    fn chooseTwoInvaders(self: *Self) void {
        // For now just pick two random invaders and swap them.
        const invTotal = self.mInvaders.items.len - 1;
        const randInvIdx: usize = @intCast(c.GetRandomValue(0, @intCast(invTotal)));
        self.mInvaderSwaps.a = &self.mInvaders.items[randInvIdx];
        self.mInvaderSwaps.aX = self.mInvaderSwaps.a.?.mX;
        self.mInvaderSwaps.aY = self.mInvaderSwaps.a.?.mY;

        var randInv2Idx: usize = randInvIdx;
        while (randInvIdx == randInv2Idx) {
            const newIdx: usize = @intCast(c.GetRandomValue(0, @intCast(invTotal)));
            self.mInvaderSwaps.b = &self.mInvaders.items[newIdx];
            self.mInvaderSwaps.bX = self.mInvaderSwaps.b.?.mX;
            self.mInvaderSwaps.bY = self.mInvaderSwaps.b.?.mY;
            randInv2Idx += 1;
            if (randInv2Idx > (invTotal - 1)) {
                randInv2Idx = 0;
            }
        }
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

    pub fn update(self: *Self) !void {
        //if (state.mGame.mTicks % 2 != 0) return;
        if (self.mInvaders.items.len == 0) {
            // TODO: Hive must have been wiped out, spawn a new wave.
            return;
        }

        switch (self.mState) {
            .Scanning => {
                // Determine the bounds of the entire swarm.
                var minX: f32 = std.math.floatMax(f32);
                var maxX: f32 = -std.math.floatMin(f32);

                for (self.mInvaders.items) |*inv| {
                    if (inv.mX < minX) {
                        minX = inv.mX;
                    }
                    // NOTE: the right side of the bounds should also include the width of the invader.
                    if (inv.mX + invWidth > maxX) {
                        maxX = inv.mX + invWidth;
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

                // Bump attack countdown.
                self.mAttackCountdown -= 1;
                if (self.mAttackCountdown <= 0) {
                    self.mState = .Attack;
                    self.mAttackCountdown = conf.AttackCooldown;
                }

                // Bump swap countdown.
                if (conf.SwapEnabled) {
                    self.mSwapCountdown -= 1;
                    if (self.mSwapCountdown <= 0) {
                        self.chooseTwoInvaders();
                        self.mState = .Swapping;
                        self.mSwapCountdown = conf.SwapCooldown;
                    }
                }
            },
            .Descending => {
                var purgeOneOrMoreDead = false;
                for (self.mInvaders.items) |*inv| {
                    inv.mY += self.mDescendingSpeed;

                    if (inv.mY >= conf.LAND_HEIGHT) {
                        inv.deathReason = .HitGround;
                        purgeOneOrMoreDead = true;
                    }
                }

                // During the descent, one or more invaders died and need to be
                // purged from the hive. The hive does not tolerate death!
                if (purgeOneOrMoreDead) {
                    var len = self.mInvaders.items.len;
                    while (len != 0) : (len -= 1) {
                        const currInv = self.mInvaders.items[len - 1];
                        if (currInv.dead()) {
                            // When invader is dead, spawn a poof explosion as well as a -1 red mini score.
                            try state.mGame.createPoofExplosion(currInv.mX, currInv.mY);

                            switch (currInv.deathReason.?) {
                                .HitGround => try state.mGame.createMiniRedFloatingScore("-1", currInv.mX, currInv.mY),
                                .PlayerProjectile => try state.mGame.createSmallWhiteFloatingScore("+20", currInv.mX, currInv.mY),
                            }

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
            .Swapping => {
                const is = &self.mInvaderSwaps;
                const invA = self.mInvaderSwaps.a.?;
                const invB = self.mInvaderSwaps.b.?;

                const easeFn = esngs.easeInOutBounce;

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
                try state.mGame.mEnemyProjectiles.append(prj.Projectile.create(selectedInv.mX, selectedInv.mY));

                self.mState = .Scanning;
            },
        }
    }
};

pub const InvaderDeathReason = enum(u8) {
    HitGround,
    PlayerProjectile,
};

pub const Invader = struct {
    mX: f32 = 0,
    mY: f32 = 0,
    // If null, player is not dead.
    deathReason: ?InvaderDeathReason = null,

    const Self = @This();

    pub inline fn dead(self: Self) bool {
        return self.deathReason != null;
    }
};
