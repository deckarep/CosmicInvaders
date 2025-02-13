const std = @import("std");
const state = @import("gamestate.zig");
const c = @import("cdefs.zig").c;
const drw = @import("draw.zig");
const txtrs = @import("textures.zig");
const conf = @import("conf.zig");

pub const WeaponStationKind = enum(u8) {
    Canon,
    TeslaCoil,
    RocketLauncher,
};

pub const WeaponStation = struct {
    mKind: WeaponStationKind,
    mX: f32 = 180,
    mY: f32 = 372,
    mHealth: u8 = 100, // express as percent or some other unit?
    mBulletCountdown: usize = 0,

    const Self = @This();

    pub fn create(kind: WeaponStationKind) Self {
        const countdown: usize = switch (kind) {
            .Canon => conf.CanonCooldown,
            .TeslaCoil => conf.TeslaCoilCooldown,
            .RocketLauncher => conf.RocketLauncherCooldown,
        };

        return Self{
            .mKind = kind,
            .mBulletCountdown = countdown,
        };
    }

    pub fn update(self: *Self) !void {
        self.mBulletCountdown -= 1;
        const shouldFire = self.mBulletCountdown == 0;

        switch (self.mKind) {
            .Canon => {
                if (shouldFire) {
                    const x = self.mX + ((29 * 2) / 2);
                    try state.mGame.spawnCanonBullet(x, self.mY);
                    c.PlaySound(txtrs.Textures.Sfx.LaserFire);
                    self.mBulletCountdown = conf.CanonCooldown;
                }
            },
            .TeslaCoil => {
                if (shouldFire) {
                    self.mBulletCountdown = conf.CanonCooldown;
                }
            },
            .RocketLauncher => {
                if (shouldFire) {
                    self.mBulletCountdown = conf.CanonCooldown;
                }
            },
        }
    }

    pub fn sell(self: *Self) void {
        _ = self;
        // TODO: compute and return salvage value, and destroy object.
    }

    pub fn repair(self: *Self) void {
        self.mHealth = 100;
    }

    pub fn applyDamage(self: *Self, amount: u32) void {
        self.mHealth -= amount;
        // TODO change state: (flash or flicker red for a few frames)
    }

    pub fn draw(self: Self) !void {
        // TODO: when below some mHealth threshold, show damage animation as well.
        // Giving the user an indication that there structure will be destroyed soon!
        switch (self.mKind) {
            .Canon => {
                const w = 29;
                const h = 29;
                //const frameSeqCount = 7;
                // const halfFrameSeqCount = frameSeqCount / 2;
                // const speedReduceFactor = 6;
                // const phase = (((state.mGame.mTicks) / speedReduceFactor)) % frameSeqCount;
                // const value = if (phase > halfFrameSeqCount) frameSeqCount - phase else phase;
                // const xOffset: f32 = @floatFromInt(value * w);
                // const yOffset: f32 = @floatFromInt(h * 0);
                const view = c.Rectangle{ .x = 0, .y = 0, .width = w, .height = h };
                drw.drawTextureScaled(
                    self.mX,
                    self.mY,
                    txtrs.Textures.Canon,
                    view,
                    2.0,
                );
            },
            .TeslaCoil => {
                // TODO
            },
            .RocketLauncher => {
                // TODO
            },
        }
    }
};
