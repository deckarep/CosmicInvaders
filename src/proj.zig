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
    getBoundsFn: *const fn (*anyopaque) c.Rectangle,
    isDeadFn: *const fn (*anyopaque) bool,
    markDeadFn: *const fn (*anyopaque) void,

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

    pub inline fn getBounds(self: Proj) c.Rectangle {
        return self.getBoundsFn(self.ptr);
    }

    pub inline fn markDead(self: Proj) void {
        self.markDeadFn(self.ptr);
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

        const selectedTexture = txtrs.Textures.LaserSm;
        const tw = selectedTexture.width;
        const th = selectedTexture.height;

        // TODO: only LaserSm is hardcoded: When upgraded, use the LaserMed texture.
        const view = c.Rectangle{
            .x = 0,
            .y = 0,
            .width = @floatFromInt(tw),
            .height = @floatFromInt(th),
        };

        drw.drawTextureScaled(self.mX, self.mY, selectedTexture, view, 2.0);

        // Draw red bounding box.
        const scale = 2;
        c.DrawRectangleLines(
            @intFromFloat(self.mX),
            @intFromFloat(self.mY),
            tw * scale,
            th * scale,
            c.RED,
        );
    }

    pub fn getPos(ptr: *anyopaque) c.Vector2 {
        const self: *CanonBullet = @alignCast(@ptrCast(ptr));
        return c.Vector2{ .x = self.mX, .y = self.mY };
    }

    pub fn getBounds(ptr: *anyopaque) c.Rectangle {
        const self: *CanonBullet = @alignCast(@ptrCast(ptr));

        const selectedTexture = txtrs.Textures.LaserSm;
        const tw: f32 = @floatFromInt(selectedTexture.width);
        const th: f32 = @floatFromInt(selectedTexture.height);
        const scale = 2.0;

        return c.Rectangle{
            .x = self.mX,
            .y = self.mY,
            .width = tw * scale,
            .height = th * scale,
        };
    }

    pub fn markDead(ptr: *anyopaque) void {
        const self: *CanonBullet = @alignCast(@ptrCast(ptr));
        self.mDead = true;
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
            .getBoundsFn = getBounds,

            .isDeadFn = isDead,
            .markDeadFn = markDead,
        };
    }
};
