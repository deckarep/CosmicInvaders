const c = @import("c");
const std = @import("std");
const res = @import("resources.zig");
const state = @import("game_state.zig");
const drw = @import("draw.zig");
const pj = @import("projectile.zig");

pub const LigteningStrike = struct {
    base: pj.BaseProjectile,
    mLifetime: usize,

    mInvaderIDToSeek: ?usize,
    mTargetPos: c.Vector2,

    const Self = @This();

    pub fn create(pos: c.Vector2, allocator: std.mem.Allocator) !*Self {
        const strike = try allocator.create(Self);
        strike.base.init(.Lightening, pos, allocator);
        strike.mLifetime = 6;
        strike.mInvaderIDToSeek = null;
        return strike;
    }

    pub fn deinit(ptr: *anyopaque) void {
        const self: *Self = @ptrCast(@alignCast(ptr));
        self.base.mAllocator.destroy(self);
    }

    fn isTrackingInvaderActive(self: *Self, invID: ?usize) bool {
        if (invID) |id| {
            return state.mGame.mHive.isInvaderIdActive(id);
        }
        // It's not longer active so we must null it out.
        self.mInvaderIDToSeek = null;
        return false;
    }

    fn findInvaderToSeek(self: *Self) void {
        const id = state.mGame.mHive.getRandomInvaderId();
        if (id) |i| {
            self.mInvaderIDToSeek = i;
            return;
        }

        self.mInvaderIDToSeek = null;
    }

    fn seekInvader(self: *Self, fallbackTarget: c.Vector2) c.Vector2 {
        const hive = &state.mGame.mHive;

        // 1. If we're already tracking an active invader, use its position for targeting.
        if (self.isTrackingInvaderActive(self.mInvaderIDToSeek)) {
            if (hive.getInvaderById(self.mInvaderIDToSeek)) |i| {
                const p = i.getPos();
                const b = i.getBounds();
                return .{ .x = p.x + b.width / 2.0, .y = p.y + b.height / 2.0 };
            }
        } else {
            // 2. If we're not, attempt to track one and use its position for targeting.
            self.findInvaderToSeek();
            if (self.mInvaderIDToSeek) |invID| {
                const i = hive.getInvaderById(invID).?;
                const p = i.getPos();
                const b = i.getBounds();
                return .{ .x = p.x + b.width / 2.0, .y = p.y + b.height / 2.0 };
            }
        }

        // 3. Otherwise, just use fallback target, whatever it might be.
        return fallbackTarget;
    }

    pub fn update(ptr: *anyopaque) anyerror!void {
        const self: *Self = @ptrCast(@alignCast(ptr));
        if (self.base.isDead()) return;

        // for lightening, don't call base update.
        // self.base.update();

        // 1. For now, target starts off default to mouse position (while we're prototyping)
        var target = c.GetMousePosition();

        // 2. Seek an invader.
        target = self.seekInvader(target);

        if (self.mInvaderIDToSeek == null) return;

        // 3. Capture the target for usage in draw.
        self.mTargetPos = target;

        if (self.mLifetime > 0) {
            self.mLifetime -= 1;
        } else {
            self.base.mDead = true;
        }
    }

    pub fn draw(ptr: *anyopaque) anyerror!void {
        const self: *Self = @ptrCast(@alignCast(ptr));
        if (self.base.isDead()) return;
        if (self.mInvaderIDToSeek == null) return;

        drw.drawLighteningStrike(self.base.mPos, self.mTargetPos);
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

        return c.Rectangle{
            .x = self.base.mPos.x,
            .y = self.base.mPos.y,
            .width = 50, //HARDCODED
            .height = 50,
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
