const std = @import("std");
const state = @import("game_state.zig");
const conf = @import("conf.zig");
const res = @import("resources.zig");
const pj = @import("projectile.zig");
const drw = @import("draw.zig");
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
    mAllocator: std.mem.Allocator,
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
            .mAllocator = allocator,
        };
    }

    pub fn init(self: *Self) !void {
        // Create the invaders.
        self.mInvaders = std.ArrayList(Invader).init(self.mAllocator);
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

    pub fn cullInvaders(self: *Self) !void {
        var howMany: usize = 0;
        var len = self.mInvaders.items.len;
        while (len != 0) : (len -= 1) {
            const currInv = self.mInvaders.items[len - 1];
            if (currInv.dead()) {
                // When invader is dead, spawn a poof explosion as well as a -1 red mini score.
                try state.mGame.createPoofExplosion(currInv.mX, currInv.mY);

                switch (currInv.mDeathReason.?) {
                    .HitGround => {
                        std.debug.print("culling invader due to hitting ground\n", .{});
                        try state.mGame.createMiniRedFloatingScore("-1", currInv.mX, currInv.mY);
                    },
                    .HitWeaponStation => {
                        std.debug.print("culling invader due to hitting a weapon station\n", .{});
                        try state.mGame.createMiniRedFloatingScore("-10", currInv.mX, currInv.mY);
                    },
                    .PlayerProjectile => {
                        try state.mGame.createSmallWhiteFloatingScore("+20", currInv.mX, currInv.mY);
                    },
                }

                _ = self.mInvaders.swapRemove(len - 1);
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

        for (self.mInvaders.items) |*inv| {
            // Capture x-axis bounds.
            if (inv.mX < minX) {
                minX = inv.mX;
            }
            // NOTE: the right side of the bounds should also include the width of the invader.
            if (inv.mX + invWidth > maxX) {
                maxX = inv.mX + invWidth;
            }

            // Capture y-axis bounds.
            if (inv.mY < minY) {
                minY = inv.mY;
            }
            // NOTE: the right side of the bounds should also include the height of the invader.
            if (inv.mY + invHeight > maxY) {
                maxY = inv.mY + invHeight;
            }
        }

        return c.Rectangle{
            .x = minX,
            .y = minY,
            .width = maxX - minX,
            .height = maxY - minY,
        };
    }

    pub fn checkInvaderCollided(self: *Self, invader: *Invader) bool {
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
                    for (self.mInvaders.items) |*inv| {
                        inv.mX += self.mHorizontalSpeed * self.mDirection;

                        // Check on any collisions for this invader.
                        if (self.checkInvaderCollided(inv)) {
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
                for (self.mInvaders.items) |*inv| {
                    inv.mY += self.mDescendingSpeed;

                    // Check on any collisions for this invader.
                    if (self.checkInvaderCollided(inv)) {
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
                const p = try pj.AlienBullet.create(selectedInv.mX, selectedInv.mY, self.mAllocator);
                const bullet = p.asProjectile();
                try state.mGame.mEnemyProjectiles.append(bullet);

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

pub const InvaderDeathReason = enum(u8) {
    HitGround,
    HitWeaponStation,
    PlayerProjectile,
};

pub const InvaderState = enum(u8) {
    Ok, // Initial state, green no damage yet.
    Damaged, // When a projectile hits.
    Marked, // Hit at least once, marked and vulnerable.
};

pub const Invader = struct {
    mX: f32 = 0,
    mY: f32 = 0,
    mHits: usize = 2,

    mFlickerCount: usize = FlickerFrames,
    mState: InvaderState = .Ok,
    mViewYOffset: f32 = 0,

    // If null, invader is not dead.
    mDeathReason: ?InvaderDeathReason = null,

    const FlickerFrames = 10;
    const Self = @This();

    pub fn update(self: *Self) void {
        switch (self.mState) {
            .Ok => {
                self.mViewYOffset = 0;
            },
            .Damaged => {
                // BUG: for some reason I don't always see the flicker render.
                self.mViewYOffset = if (self.mFlickerCount % 3 == 0) 0 else 1;

                if (self.mFlickerCount <= 0) {
                    self.mFlickerCount = FlickerFrames;
                    self.mState = .Marked;
                } else {
                    self.mFlickerCount -= 1;
                }
            },
            .Marked => {
                self.mViewYOffset = 2;
            },
        }
    }

    pub fn draw(self: Self) void {
        const width = 16;
        const height = 13;
        const frameSeqCount = 6;
        const halfFrameSeqCount = frameSeqCount / 2;
        const speedReduceFactor = 10;
        const scale = 2.0;

        // Division is used to slow the ticks down a bit.
        // Using ticks as a stream of numbers, generates 0-5 inclusive
        // Using the idx, causes the animations to offset by idx number.
        const phase = (((state.mGame.mTicks) / speedReduceFactor)) % frameSeqCount;
        // Then the upper half of the numbers are subtracted from 6, to create a
        // repeating pattern that goes up and down in sequence.
        const value = if (phase > halfFrameSeqCount) frameSeqCount - phase else phase;
        const xOffset: f32 = @floatFromInt(value * width);
        const yOffset: f32 = @as(f32, @floatFromInt(height)) * self.mViewYOffset;

        const view = c.Rectangle{
            .x = xOffset,
            .y = yOffset,
            .width = width,
            .height = height,
        };

        drw.drawTextureScaled(
            self.mX,
            self.mY,
            res.Resources.Invader1,
            view,
            scale,
        );

        // Debug inv bounds.
        const invBounds = self.getBounds();
        c.DrawRectangleLines(
            @intFromFloat(invBounds.x),
            @intFromFloat(invBounds.y),
            @intFromFloat(invBounds.width),
            @intFromFloat(invBounds.height),
            c.RED,
        );
    }

    pub inline fn getPos(self: Self) c.Vector2 {
        return c.Vector2{ .x = self.mX, .y = self.mY };
    }

    pub inline fn getBounds(self: Self) c.Rectangle {
        return c.Rectangle{
            .x = self.mX,
            .y = self.mY,
            .width = invWidth,
            .height = invHeight,
        };
    }

    pub inline fn dead(self: Self) bool {
        return self.mDeathReason != null;
    }

    pub fn checkHit(self: *Self, projBounds: c.Rectangle) bool {
        const invBounds = self.getBounds();

        const collided = c.CheckCollisionRecs(projBounds, invBounds);
        if (collided) {
            self.mHits -= 1;

            // Put the invader into damaged mode.
            self.mState = .Damaged;

            if (self.mHits == 0) {
                self.mDeathReason = .PlayerProjectile;
            }
        }

        return collided;
    }
};
