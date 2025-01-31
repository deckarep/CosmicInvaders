const std = @import("std");
const state = @import("gamestate.zig");
const conf = @import("conf.zig");
const c = @import("cdefs.zig").c;

pub const HiveState = enum {
    Scanning, // horizontal movement in either direction (left or right)
    Descending, // ticking closer to player
    Attack,
    Hit,
    Dying,
};

pub const Hive = struct {
    mInvaders: std.ArrayList(Invader) = undefined,
    mDirection: i32 = 1,
    mHorizontalSpeed: i32 = 1,
    mDescendingSpeed: i32 = 1,
    mDescendCountdown: i32 = conf.DescendCountdown,
    mAttackCountdown: i32 = conf.AttackCooldown,
    mState: HiveState = .Scanning,

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator) Self {
        var invaders = std.ArrayList(Invader).init(allocator);
        invaders.append(Invader{ .mY = 20 }) catch unreachable;

        return Self{
            .mInvaders = invaders,
        };
    }

    pub fn deinit(self: *Self) void {
        self.mInvaders.deinit();
    }

    // TODO: some kind of functions to initialize the invader count.

    pub fn update(self: *Self) !void {
        if (state.mGame.mTicks % 2 != 0) return;

        switch (self.mState) {
            .Scanning => {
                for (self.mInvaders.items) |*inv| {
                    inv.mX += self.mHorizontalSpeed * self.mDirection;
                    if (inv.mX > conf.WIN_WIDTH or inv.mX < 0) {
                        self.mDescendCountdown = conf.DescendCountdown;
                        self.mDirection *= -1;
                        self.mState = .Descending;
                    }
                }
                self.mAttackCountdown -= 1;

                if (self.mAttackCountdown <= 0) {
                    self.mState = .Attack;
                    self.mAttackCountdown = conf.AttackCooldown;
                }
            },
            .Descending => {
                for (self.mInvaders.items) |*inv| {
                    inv.mY += self.mDescendingSpeed;
                }
                self.mDescendCountdown -= 1;
                if (self.mDescendCountdown <= 0) {
                    self.mState = .Scanning;
                }
            },
            .Attack => {
                // Choose random invader to attack.
                const invIdx = self.mInvaders.items.len - 1;
                const selectedInv = self.mInvaders.items[invIdx];
                try state.mGame.mEnemyProjectiles.append(.{ .mX = selectedInv.mX, .mY = selectedInv.mY });

                self.mState = .Scanning;
            },
            .Hit => {},
            .Dying => {},
        }
    }
};

pub const Invader = struct {
    mX: i32 = 0,
    mY: i32 = 0,

    const Self = @This();
};
