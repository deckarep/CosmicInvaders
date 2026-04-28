const c = @import("c");
const std = @import("std");
const res = @import("resources.zig");
const drw = @import("draw.zig");
const pj = @import("projectile.zig");

pub const CanonBullet = struct {
    base: pj.BaseProjectile,

    const Self = @This();

    pub fn create(x: f32, y: f32, allocator: std.mem.Allocator) !*Self {
        const bullet = try allocator.create(Self);
        bullet.base.init(.Canon, x, y, allocator);
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

        self.base.mPos.y -= 6;
    }

    pub fn draw(ptr: *anyopaque) anyerror!void {
        const self: *Self = @ptrCast(@alignCast(ptr));
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

        drw.drawTextureScaled(self.base.mPos.x, self.base.mPos.y, selectedTexture, view, 2.0, c.WHITE);

        // Draw red bounding box.
        const scale = 2;
        c.DrawRectangleLines(
            @intFromFloat(self.base.mPos.x),
            @intFromFloat(self.base.mPos.y),
            tw * scale,
            th * scale,
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

        const selectedTexture = res.Resources.LaserSm;
        const tw: f32 = @floatFromInt(selectedTexture.width);
        const th: f32 = @floatFromInt(selectedTexture.height);
        const scale = 2.0;

        return c.Rectangle{
            .x = self.base.mPos.x,
            .y = self.base.mPos.y,
            .width = tw * scale,
            .height = th * scale,
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
