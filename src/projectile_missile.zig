const c = @import("c");
const std = @import("std");
const res = @import("resources.zig");
const state = @import("game_state.zig");
const drw = @import("draw.zig");
const pj = @import("projectile.zig");

pub const MissileProj = struct {
    base: pj.BaseProjectile,

    mTexture: c.Texture = undefined,
    mRotation: f32 = 0.0,
    mSpeed: f32, // pixels per second.
    mPlumeCooldown: f32,

    // mInvaderIDToSeek allows us to query to the hive to see if invader is alive.
    mInvaderIDToSeek: ?usize,

    const Self = @This();
    const PlumeEveryNFrames = 10;

    pub fn create(x: f32, y: f32, rot: f32, allocator: std.mem.Allocator) !*Self {
        const missile = try allocator.create(Self);
        missile.base.init(.Missile, x, y, allocator);
        missile.mRotation = rot;
        missile.mSpeed = @floatFromInt(c.GetRandomValue(60, 75));
        missile.mPlumeCooldown = PlumeEveryNFrames; // config this
        missile.mTexture = res.Resources.Projectiles.Missile;
        missile.mInvaderIDToSeek = null;
        return missile;
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
                return i.getPos();
            }
        } else {
            // 2. If we're not, attempt to track one and use its position for targeting.
            self.findInvaderToSeek();
            if (self.mInvaderIDToSeek) |invID| {
                const i = hive.getInvaderById(invID).?;
                return i.getPos();
            }
        }

        // 3. Otherwise, just use fallback target, whatever it might be.
        return fallbackTarget;
    }

    pub fn update(ptr: *anyopaque) anyerror!void {
        const self: *Self = @ptrCast(@alignCast(ptr));
        if (self.base.isDead()) return;

        self.base.update();

        // Move towards target: (mouse pos for now)
        const myPos = self.base.mPos;

        // 1. For now, target starts off default to mouse position (while we're prototyping)
        var target = c.GetMousePosition();

        // 2. Seek an invader.
        target = self.seekInvader(target);

        const maxDist: f32 = self.mSpeed * c.GetFrameTime();
        const resultVec = c.Vector2MoveTowards(
            myPos,
            target,
            maxDist,
        );

        self.base.mPos = resultVec;

        // Orient towards target.
        const dir = c.Vector2{
            .x = target.x - myPos.x,
            .y = myPos.y - target.y, // flip Y
        };
        const angleRad = std.math.atan2(dir.y, dir.x);
        var angleDeg = angleRad * (180.0) / std.math.pi;
        if (angleDeg < 0) angleDeg += 360.0;

        self.mRotation = angleDeg - 90; // subtract 90 to fix orientation.
        self.mRotation = @mod(self.mRotation, 360.0);

        if (self.mPlumeCooldown > 0) {
            self.mPlumeCooldown -= 1;
        }

        if (self.mPlumeCooldown == 0) {
            try state.mGame.spawnPuff2Explosion(.{ .x = myPos.x + 4, .y = myPos.y + 4 });
            self.mPlumeCooldown = PlumeEveryNFrames;
        }
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

    pub fn getKind(ptr: *anyopaque) pj.ProjKind {
        const self: *Self = @ptrCast(@alignCast(ptr));
        return self.base.getKind();
    }

    pub fn draw(ptr: *anyopaque) anyerror!void {
        const self: *Self = @ptrCast(@alignCast(ptr));
        if (self.base.isDead()) return;

        // The missle sprite starts: -> direction and goes counter clockwise. 2 rows, 8 sprites per row.
        // 0   = right
        // 90  = up
        // 180 = left
        // 270 = down
        const frameCount = 16.0;
        const rotSegment = 360.0 / frameCount;

        // Missile art starts pointing right.
        var normalizedRot = @mod(self.mRotation + 90.0, 360.0);
        if (normalizedRot < 0.0) normalizedRot += 360.0;

        const frame: usize = @as(usize, @intFromFloat(@floor(normalizedRot / rotSegment))) % 16;

        const celXOffset: f32 = @floatFromInt(frame % 8);
        const celYOffset: f32 = @floatFromInt(frame / 8);

        const celw = 8.0;
        const celh = 8.0;

        const view = c.Rectangle{
            .x = celXOffset * celw,
            .y = celYOffset * celh,
            .width = celw,
            .height = celh,
        };

        const scale = 2;
        drw.drawTextureScaled(self.base.mPos.x, self.base.mPos.y, self.mTexture, view, scale, c.WHITE);

        //std.debug.print("rot => {d}\n", .{self.mRotation});

        // Draw red bounding box.
        c.DrawRectangleLines(
            @intFromFloat(self.base.mPos.x),
            @intFromFloat(self.base.mPos.y),
            celw * scale,
            celh * scale,
            c.RED,
        );
    }

    pub fn getBounds(ptr: *anyopaque) c.Rectangle {
        const self: *Self = @ptrCast(@alignCast(ptr));

        const tw: f32 = 8.0;
        const th: f32 = 8.0;
        const scale = 2.0;

        return c.Rectangle{
            .x = self.base.mPos.x,
            .y = self.base.mPos.y,
            .width = tw * scale,
            .height = th * scale,
        };
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
