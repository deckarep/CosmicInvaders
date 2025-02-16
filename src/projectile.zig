const std = @import("std");
const c = @import("cdefs.zig").c;
const conf = @import("conf.zig");
const res = @import("resources.zig");
const drw = @import("draw.zig");
const state = @import("game_state.zig");

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

pub const BaseProjectile = struct {
    mAllocator: std.mem.Allocator,
    mX: f32 = 0,
    mY: f32 = 0,
    mDead: bool,

    const Self = @This();

    inline fn init(self: *Self, x: f32, y: f32, allocator: std.mem.Allocator) void {
        self.mAllocator = allocator;
        self.mX = x;
        self.mY = y;
        self.mDead = false;
    }

    inline fn update(self: *Self) void {
        // Check when out of bounds.
        if (self.mY < 0 or self.mY > conf.WIN_HEIGHT) self.mDead = true;
        if (self.mX < 0 or self.mX > conf.WIN_WIDTH) self.mDead = true;
    }

    inline fn markDead(self: *Self) void {
        self.mDead = true;
    }

    inline fn isDead(self: *Self) bool {
        return self.mDead;
    }

    inline fn getPos(self: *Self) c.Vector2 {
        return c.Vector2{ .x = self.mX, .y = self.mY };
    }
};

pub const AlienBullet = struct {
    base: BaseProjectile,
    mfixedX: f32 = 0,

    const Self = @This();

    pub fn create(x: f32, y: f32, allocator: std.mem.Allocator) !*AlienBullet {
        const bullet = try allocator.create(AlienBullet);
        bullet.base.init(x, y, allocator);
        bullet.mfixedX = x; // <-- anchor around this x.
        return bullet;
    }

    pub fn deinit(ptr: *anyopaque) void {
        const self: *Self = @alignCast(@ptrCast(ptr));
        self.base.mAllocator.destroy(self);
    }

    pub fn update(ptr: *anyopaque) anyerror!void {
        const self: *Self = @alignCast(@ptrCast(ptr));
        if (self.base.isDead()) return;

        self.base.update();

        self.base.mY += conf.EnemyProjectileYSpeed;

        const amplitude = 30.0;
        const frequency = 1.0 / 15.0; // adjust this to get the desired period
        self.base.mX = self.mfixedX + amplitude * @sin(@as(f32, @floatFromInt(state.mGame.mTicks)) * frequency);
    }

    pub fn draw(ptr: *anyopaque) anyerror!void {
        const self: *Self = @alignCast(@ptrCast(ptr));
        if (self.base.isDead()) return;

        const w = 5;
        const h = 5;
        const frameSeqCount = 7;
        const halfFrameSeqCount = frameSeqCount / 2;
        const speedReduceFactor = 6;
        const phase = (((state.mGame.mTicks) / speedReduceFactor)) % frameSeqCount;
        const value = if (phase > halfFrameSeqCount) frameSeqCount - phase else phase;
        const xOffset: f32 = @floatFromInt(value * w);
        const yOffset: f32 = @floatFromInt(h * 0);
        const view = c.Rectangle{ .x = xOffset, .y = yOffset, .width = 5, .height = 5 };
        // NOTE: to call the interface getPos we have to pass in the raw ptr. Yechy.
        const prjPos = getPos(ptr);
        drw.drawTextureScaled(prjPos.x, prjPos.y, res.Resources.AlienBullet, view, 2.0);
    }

    pub fn markDead(ptr: *anyopaque) void {
        const self: *Self = @alignCast(@ptrCast(ptr));
        self.base.markDead();
    }

    pub fn isDead(ptr: *anyopaque) bool {
        const self: *Self = @alignCast(@ptrCast(ptr));
        return self.base.isDead();
    }

    pub fn getPos(ptr: *anyopaque) c.Vector2 {
        const self: *Self = @alignCast(@ptrCast(ptr));
        return self.base.getPos();
    }

    pub fn getBounds(ptr: *anyopaque) c.Rectangle {
        const self: *Self = @alignCast(@ptrCast(ptr));

        const scale = 2.0;

        return c.Rectangle{
            .x = self.base.mX,
            .y = self.base.mY,
            .width = @as(f32, @floatFromInt(res.Resources.AlienBullet.width)) * scale,
            .height = @as(f32, @floatFromInt(res.Resources.AlienBullet.height)) * scale,
        };
    }

    pub fn asProjectile(self: *Self) Proj {
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

pub const CanonBullet = struct {
    base: BaseProjectile,

    const Self = @This();

    pub fn create(x: f32, y: f32, allocator: std.mem.Allocator) !*Self {
        const bullet = try allocator.create(Self);
        bullet.base.init(x, y, allocator);
        return bullet;
    }

    pub fn deinit(ptr: *anyopaque) void {
        const self: *Self = @alignCast(@ptrCast(ptr));
        self.base.mAllocator.destroy(self);
    }

    pub fn update(ptr: *anyopaque) anyerror!void {
        const self: *Self = @alignCast(@ptrCast(ptr));
        if (self.base.isDead()) return;

        self.base.update();

        self.base.mY -= 6;
    }

    pub fn draw(ptr: *anyopaque) anyerror!void {
        const self: *Self = @alignCast(@ptrCast(ptr));
        if (self.base.isDead()) return;

        const selectedTexture = res.Resources.LaserSm;
        const tw = selectedTexture.width;
        const th = selectedTexture.height;

        // TODO: only LaserSm is hardcoded: When upgraded, use the LaserMed texture.
        const view = c.Rectangle{
            .x = 0,
            .y = 0,
            .width = @floatFromInt(tw),
            .height = @floatFromInt(th),
        };

        drw.drawTextureScaled(self.base.mX, self.base.mY, selectedTexture, view, 2.0);

        // Draw red bounding box.
        const scale = 2;
        c.DrawRectangleLines(
            @intFromFloat(self.base.mX),
            @intFromFloat(self.base.mY),
            tw * scale,
            th * scale,
            c.RED,
        );
    }

    pub fn markDead(ptr: *anyopaque) void {
        const self: *Self = @alignCast(@ptrCast(ptr));
        self.base.markDead();
    }

    pub fn isDead(ptr: *anyopaque) bool {
        const self: *Self = @alignCast(@ptrCast(ptr));
        return self.base.isDead();
    }

    pub fn getPos(ptr: *anyopaque) c.Vector2 {
        const self: *Self = @alignCast(@ptrCast(ptr));
        return self.base.getPos();
    }

    pub fn getBounds(ptr: *anyopaque) c.Rectangle {
        const self: *Self = @alignCast(@ptrCast(ptr));

        const selectedTexture = res.Resources.LaserSm;
        const tw: f32 = @floatFromInt(selectedTexture.width);
        const th: f32 = @floatFromInt(selectedTexture.height);
        const scale = 2.0;

        return c.Rectangle{
            .x = self.base.mX,
            .y = self.base.mY,
            .width = tw * scale,
            .height = th * scale,
        };
    }

    pub fn asProjectile(self: *Self) Proj {
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
