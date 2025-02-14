const std = @import("std");
const state = @import("gamestate.zig");
const c = @import("cdefs.zig").c;
const drw = @import("draw.zig");
const res = @import("resources.zig");
const conf = @import("conf.zig");

pub const WeaponStationKind = enum(u8) {
    Canon,
    TeslaCoil,
    RocketLauncher,
};

pub const StationCondition = enum(u8) {
    New,
    LowHealth,
    Exploding,
    Dead,
};

pub const WeaponStation = struct {
    mKind: WeaponStationKind,
    mCondition: StationCondition = .New,
    mX: f32 = 180,
    mY: f32 = 372,
    mHealth: u8 = 100, // express as percent or some other unit?
    mFireCountdown: usize = 0,

    const Self = @This();

    pub fn create(kind: WeaponStationKind) Self {
        const countdown: usize = switch (kind) {
            .Canon => conf.CanonCooldown,
            .TeslaCoil => conf.TeslaCoilCooldown,
            .RocketLauncher => conf.RocketLauncherCooldown,
        };

        return Self{
            .mKind = kind,
            .mFireCountdown = countdown,
        };
    }

    pub fn update(self: *Self) !void {
        self.mFireCountdown -= 1;
        const shouldFire = self.mFireCountdown == 0;

        switch (self.mKind) {
            .Canon => {
                if (shouldFire) {
                    const x = self.mX + ((29 * 2) / 2);
                    try state.mGame.spawnCanonBullet(x, self.mY);
                    c.PlaySound(res.Resources.Sfx.LaserFire);
                    self.mFireCountdown = conf.CanonCooldown;
                }
            },
            .TeslaCoil => {
                if (shouldFire) {
                    self.mFireCountdown = conf.CanonCooldown;
                }
            },
            .RocketLauncher => {
                if (shouldFire) {
                    self.mFireCountdown = conf.CanonCooldown;
                }
            },
        }
    }

    // This returns the true bounding box.
    pub fn getTrueBounds(self: Self) c.Rectangle {
        const scale = 2.0;

        const wh = switch (self.mKind) {
            .Canon => c.Vector2{ .x = 29, .y = 29 },
            // Below values are hardcoded for now.
            .TeslaCoil => c.Vector2{ .x = 29, .y = 29 },
            .RocketLauncher => c.Vector2{ .x = 29, .y = 29 },
        };

        return c.Rectangle{
            .x = self.mX,
            .y = self.mY,
            .width = wh.x * scale,
            .height = wh.y * scale,
        };
    }

    // This returns the fudged bounding box, that's been tightened up
    // for more accurate hitbox detection.
    pub inline fn getBounds(self: Self) c.Rectangle {
        var rect = self.getTrueBounds();

        switch (self.mKind) {
            .Canon => {
                rect.x += 5;
                rect.width -= 10;
                rect.y += 20;
                rect.height -= 20;
            },
            .TeslaCoil => {},
            .RocketLauncher => {},
        }

        return rect;
    }

    pub fn sell(self: *Self) void {
        _ = self;
        // TODO: compute and return salvage value, and destroy object.
    }

    pub fn repair(self: *Self) void {
        self.mHealth = 100;
    }

    pub inline fn dead(self: Self) bool {
        return self.mHealth <= 0;
    }

    pub fn checkHit(self: *Self, projBounds: c.Rectangle, amount: u8) bool {
        if (self.dead()) return true;

        if (c.CheckCollisionRecs(projBounds, self.getBounds())) {
            self.mHealth -= amount;

            // TODO change state: (flash or flicker red for a few frames)
            std.debug.print("weapon station hit: {d}\n", .{self.mHealth});
            return true;
        }

        return false;
    }

    fn drawHealth(self: Self, bounds: c.Rectangle) void {
        // Draw health box.
        const health = (@as(f32, @floatFromInt(self.mHealth)) * bounds.width) / 100.0;

        c.DrawRectangle(
            @intFromFloat(bounds.x),
            @intFromFloat(bounds.y + bounds.height + 2),
            @intFromFloat(health),
            @intFromFloat(6),
            c.GREEN,
        );

        c.DrawRectangleLines(
            @intFromFloat(bounds.x),
            @intFromFloat(bounds.y + bounds.height + 2),
            @intFromFloat(bounds.width),
            @intFromFloat(6),
            c.RED,
        );
    }

    pub fn draw(self: Self) !void {
        if (self.dead()) return;

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
                    res.Resources.Canon,
                    view,
                    2.0,
                );

                const bounds = self.getBounds();

                // Draw health box.
                self.drawHealth(bounds);

                // Draw hit box
                c.DrawRectangleLines(
                    @intFromFloat(bounds.x),
                    @intFromFloat(bounds.y),
                    @intFromFloat(bounds.width),
                    @intFromFloat(bounds.height),
                    c.RED,
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
