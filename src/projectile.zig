const std = @import("std");
const c = @import("c");
const conf = @import("conf.zig");
const res = @import("resources.zig");
const inv = @import("invader.zig");
const drw = @import("draw.zig");
const state = @import("game_state.zig");

pub const ProjKind = enum(u8) {
    // Alien projectiles below
    AlienBullet,
    // Player projectiles below
    Canon,
    Missile,
    Lightening,
};

pub const Proj = struct {
    ptr: *anyopaque,

    deinitFn: *const fn (*anyopaque) void,
    updateFn: *const fn (*anyopaque) anyerror!void,
    drawFn: *const fn (*anyopaque) anyerror!void,
    getPosFn: *const fn (*anyopaque) c.Vector2,
    getBoundsFn: *const fn (*anyopaque) c.Rectangle,
    getKindFn: *const fn (*anyopaque) ProjKind,
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

    pub inline fn getKind(self: Proj) ProjKind {
        return self.getKindFn(self.ptr);
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
    mKind: ProjKind,

    const Self = @This();

    inline fn init(self: *Self, kind: ProjKind, x: f32, y: f32, allocator: std.mem.Allocator) void {
        self.mAllocator = allocator;
        self.mKind = kind;
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
        return .{ .x = self.mX, .y = self.mY };
    }

    inline fn getKind(self: *Self) ProjKind {
        return self.mKind;
    }
};

pub const AlienBullet = struct {
    base: BaseProjectile,
    mfixedX: f32 = 0,

    const Self = @This();

    pub fn create(x: f32, y: f32, allocator: std.mem.Allocator) !*AlienBullet {
        const bullet = try allocator.create(AlienBullet);
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

        self.base.mY += conf.EnemyProjectileYSpeed;

        const amplitude = 30.0;
        const frequency = 1.0 / 15.0; // adjust this to get the desired period
        self.base.mX = self.mfixedX + amplitude * @sin(@as(f32, @floatFromInt(state.mGame.mTicks)) * frequency);
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
            @intFromFloat(self.base.mX),
            @intFromFloat(self.base.mY),
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
            .x = self.base.mX,
            .y = self.base.mY,
            .width = @as(f32, @floatFromInt(res.Resources.AlienBullet.width)) * scale,
            .height = @as(f32, @floatFromInt(res.Resources.AlienBullet.height)) * scale,
        };
    }

    pub fn getKind(ptr: *anyopaque) ProjKind {
        const self: *Self = @ptrCast(@alignCast(ptr));
        return self.base.getKind();
    }

    pub fn asProjectile(self: *Self) Proj {
        return Proj{
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

pub const MissileProj = struct {
    base: BaseProjectile,

    mTexture: c.Texture = undefined,
    mRotation: f32 = 0.0,
    mSpeed: f32, // pixels per second.
    mPlumeCooldown: f32,

    // mInvaderIDToSeek allows us to query to the hive to see if invader is alive.
    mInvaderIDToSeek: ?usize,
    // mInvader is the actual pointer to the invader that is alive, and only valid if we have proven it's alive using the id.
    //mInvader: ?*inv.Invader,

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
            return state.mGame.mHive.mActiveInvaders.contains(id);
        }
        // It's not longer active so we must null it out.
        self.mInvaderIDToSeek = null;
        return false;
    }

    // fetchInvaderByID when provided an active invader, returns an pointer to the actual invader otherwise null if not found.
    fn fetchInvaderByID(_: Self, invID: ?usize) ?*inv.Invader {
        if (invID == null) {
            return null;
        }
        for (state.mGame.mHive.mInvaders.items) |*i| {
            if (i.mID == invID.?) {
                return i;
            }
        }

        // We should never get here if we've provided an active id, it's a bug otherwise.
        unreachable;
    }

    fn findInvaderToSeek(self: *Self) void {
        // Here's the deal, I'm not happy with this for a few reasons:
        // 1. It peeks directly into the hives arraylist, bad for encapsulation.
        const activeInvCount: c_int = @intCast(state.mGame.mHive.mActiveInvaders.cardinality());
        if (activeInvCount > 0) {
            // TODO: choose a random invader by choosing a random index.
            const randIdx: usize = @intCast(c.GetRandomValue(0, activeInvCount - 1));
            var iter = state.mGame.mHive.mActiveInvaders.iterator();
            var whichID: usize = 0;
            var idx: usize = 0;
            while (iter.next()) |id| {
                whichID = id.*;
                if (randIdx == idx) {
                    break;
                }
                idx += 1;
            }
            self.mInvaderIDToSeek = whichID;
            return;
        }

        // When no invaders are left, we can't seek to anything so set it to null.
        self.mInvaderIDToSeek = null;
    }

    fn seekInvader(self: *Self, fallbackTarget: c.Vector2) c.Vector2 {
        // 1. If we're already tracking an active invader, use its position for targeting.
        if (self.isTrackingInvaderActive(self.mInvaderIDToSeek)) {
            if (self.fetchInvaderByID(self.mInvaderIDToSeek)) |i| {
                return .{ .x = i.mX, .y = i.mY };
            }
        } else {
            // 2. If we're not, attempt to track one and use its position for targeting.
            self.findInvaderToSeek();
            if (self.mInvaderIDToSeek) |invID| {
                const i = self.fetchInvaderByID(invID).?;
                return .{ .x = i.mX, .y = i.mY };
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
        const myPos = c.Vector2{ .x = self.base.mX, .y = self.base.mY };

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

        self.base.mX = resultVec.x;
        self.base.mY = resultVec.y;

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
            try state.mGame.spawnPuff2Explosion(myPos.x + 4, myPos.y + 4);
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

    pub fn getKind(ptr: *anyopaque) ProjKind {
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
        drw.drawTextureScaled(self.base.mX, self.base.mY, self.mTexture, view, scale, c.WHITE);

        //std.debug.print("rot => {d}\n", .{self.mRotation});

        // Draw red bounding box.
        c.DrawRectangleLines(
            @intFromFloat(self.base.mX),
            @intFromFloat(self.base.mY),
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
            .getKindFn = getKind,

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

        self.base.mY -= 6;
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

        drw.drawTextureScaled(self.base.mX, self.base.mY, selectedTexture, view, 2.0, c.WHITE);

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
            .x = self.base.mX,
            .y = self.base.mY,
            .width = tw * scale,
            .height = th * scale,
        };
    }

    pub fn getKind(ptr: *anyopaque) ProjKind {
        const self: *Self = @ptrCast(@alignCast(ptr));
        return self.base.getKind();
    }

    pub fn asProjectile(self: *Self) Proj {
        return Proj{
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
