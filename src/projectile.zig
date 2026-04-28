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
    mPos: c.Vector2,
    mDead: bool,
    mKind: ProjKind,

    const Self = @This();

    pub inline fn init(self: *Self, kind: ProjKind, pos: c.Vector2, allocator: std.mem.Allocator) void {
        self.mAllocator = allocator;
        self.mKind = kind;
        self.mPos = pos;
        self.mDead = false;
    }

    pub inline fn update(self: *Self) void {
        // Check when out of bounds.
        const screenRect = c.Rectangle{
            .x = 0,
            .y = 0,
            .width = conf.WIN_WIDTH,
            .height = conf.WIN_HEIGHT,
        };
        if (!c.CheckCollisionPointRec(self.mPos, screenRect)) {
            self.mDead = true;
        }
    }

    pub inline fn markDead(self: *Self) void {
        self.mDead = true;
    }

    pub inline fn isDead(self: *Self) bool {
        return self.mDead;
    }

    pub inline fn getPos(self: *Self) c.Vector2 {
        return self.mPos;
    }

    pub inline fn getKind(self: *Self) ProjKind {
        return self.mKind;
    }
};
