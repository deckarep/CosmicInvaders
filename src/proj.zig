const std = @import("std");
const c = @import("cdefs.zig").c;
const conf = @import("conf.zig");
const txtrs = @import("textures.zig");
const drw = @import("draw.zig");

pub const Proj = struct {
    ptr: *anyopaque,

    deinitFn: *const fn (*anyopaque) void,
    updateFn: *const fn (*anyopaque) anyerror!void,
    drawFn: *const fn (*anyopaque) anyerror!void,
    getPosFn: *const fn (*anyopaque) c.Vector2,
    isDeadFn: *const fn (*anyopaque) bool,

    pub inline fn deinit(self: Proj) void {
        return self.deinitFn(self.ptr);
    }

    pub inline fn update(self: Proj) !void {
        return self.updateFn(self.ptr);
    }

    pub inline fn draw(self: Proj) !void {
        return self.drawFn(self.ptr);
    }

    pub inline fn getPos(self: Proj) c.Vector2 {
        return self.getPosFn(self.ptr);
    }

    pub inline fn isDead(self: Proj) bool {
        return self.isDeadFn(self.ptr);
    }
};

pub const CanonBullet = struct {
    mAllocator: std.mem.Allocator,
    mX: f32 = 0,
    mY: f32 = 0,
    mDead: bool = false,

    pub fn create(x: f32, y: f32, allocator: std.mem.Allocator) !*CanonBullet {
        const bullet = try allocator.create(CanonBullet);
        bullet.mAllocator = allocator;
        bullet.mX = x;
        bullet.mY = y;
        return bullet;
    }

    pub fn deinit(ptr: *anyopaque) void {
        const self: *CanonBullet = @alignCast(@ptrCast(ptr));
        self.mAllocator.destroy(self);
    }

    pub fn update(ptr: *anyopaque) anyerror!void {
        const self: *CanonBullet = @alignCast(@ptrCast(ptr));
        if (self.mDead) return;

        self.mY -= 4;

        // Check when out of bounds.
        if (self.mY < 0 or self.mY > conf.WIN_HEIGHT) self.mDead = true;
        if (self.mX < 0 or self.mX > conf.WIN_WIDTH) self.mDead = true;
    }

    pub fn draw(ptr: *anyopaque) anyerror!void {
        const self: *CanonBullet = @alignCast(@ptrCast(ptr));
        if (self.mDead) return;

        // TODO: only LaserSm is hardcoded, when upgraded do the medium one.
        const view = c.Rectangle{ .x = 0, .y = 0, .width = 1, .height = 11 };
        drw.drawTextureScaled(self.mX, self.mY, txtrs.Textures.LaserSm, view, 2.0);
    }

    pub fn getPos(ptr: *anyopaque) c.Vector2 {
        const self: *CanonBullet = @alignCast(@ptrCast(ptr));
        return c.Vector2{ .x = self.mX, .y = self.mY };
    }

    pub fn isDead(ptr: *anyopaque) bool {
        const self: *CanonBullet = @alignCast(@ptrCast(ptr));
        return self.mDead;
    }

    pub fn asProjectile(self: *CanonBullet) Proj {
        return Proj{
            .ptr = self,

            .deinitFn = deinit,
            .updateFn = update,
            .drawFn = draw,

            .getPosFn = getPos,
            .isDeadFn = isDead,
        };
    }
};
