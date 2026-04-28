const c = @import("c");
const std = @import("std");
const res = @import("resources.zig");
const state = @import("game_state.zig");
const conf = @import("conf.zig");
const drw = @import("draw.zig");
const pj = @import("projectile.zig");

pub const InvaderBullet = struct {
    base: pj.BaseProjectile,
    mfixedX: f32 = 0,

    const Self = @This();

    pub fn create(x: f32, y: f32, allocator: std.mem.Allocator) !*Self {
        const bullet = try allocator.create(Self);
        bullet.base.init(.AlienBullet, x, y, allocator);
        bullet.mfixedX = x; // <-- anchor around this x.
        return bullet;
    }

    pub fn deinit(ptr: *anyopaque) void {
        const self: *Self = @ptrCast(@alignCast(ptr));
        self.base.mAllocator.destroy(self);
    }

    pub fn update(ptr: *anyopaque) anyerror!void {
        const self: *Self = @ptrCast(@alignCast(ptr));
        if (self.base.isDead()) return;

        self.base.update();

        self.base.mPos.y += conf.EnemyProjectileYSpeed;

        const amplitude = 30.0;
        const frequency = 1.0 / 15.0; // adjust this to get the desired period

        self.base.mPos.x = self.mfixedX + amplitude * @sin(@as(f32, @floatFromInt(state.mGame.mTicks)) * frequency);
    }

    pub fn draw(ptr: *anyopaque) anyerror!void {
        const self: *Self = @ptrCast(@alignCast(ptr));
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
        drw.drawTextureScaled(prjPos.x, prjPos.y, res.Resources.AlienBullet, view, 2.0, c.WHITE);

        // Draw red bounding box.
        self.debug_draw(w, h);
    }

    fn debug_draw(self: Self, w: comptime_int, h: comptime_int) void {
        const scale = 2;
        c.DrawRectangleLines(
            @intFromFloat(self.base.mPos.x),
            @intFromFloat(self.base.mPos.y),
            w * scale,
            h * scale,
            c.RED,
        );
    }

    pub fn markDead(ptr: *anyopaque) void {
        const self: *Self = @ptrCast(@alignCast(ptr));
        self.base.markDead();
    }

    pub fn isDead(ptr: *anyopaque) bool {
        const self: *Self = @ptrCast(@alignCast(ptr));
        return self.base.isDead();
    }

    pub fn getPos(ptr: *anyopaque) c.Vector2 {
        const self: *Self = @ptrCast(@alignCast(ptr));
        return self.base.getPos();
    }

    pub fn getBounds(ptr: *anyopaque) c.Rectangle {
        const self: *Self = @ptrCast(@alignCast(ptr));

        const scale = 2.0;

        return c.Rectangle{
            .x = self.base.mPos.x,
            .y = self.base.mPos.y,
            .width = @as(f32, @floatFromInt(res.Resources.AlienBullet.width)) * scale,
            .height = @as(f32, @floatFromInt(res.Resources.AlienBullet.height)) * scale,
        };
    }

    pub fn getKind(ptr: *anyopaque) pj.ProjKind {
        const self: *Self = @ptrCast(@alignCast(ptr));
        return self.base.getKind();
    }

    pub fn asProjectile(self: *Self) pj.Proj {
        return pj.Proj{
            .ptr = self,

            .deinitFn = deinit,
            .updateFn = update,
            .drawFn = draw,

            .getPosFn = getPos,
            .getBoundsFn = getBounds,
            .getKindFn = getKind,

            .isDeadFn = isDead,
            .markDeadFn = markDead,
        };
    }
};
