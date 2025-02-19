const std = @import("std");

// Not super happy with this...coming back to it.

pub const IBase = struct {
    ptr: *anyopaque,
    publishFn: *const fn (ptr: *anyopaque, msg: []const u8) void,

    const Self = @This();

    pub fn publish(self: Self, msg: []const u8) void {
        self.publishFn(self.ptr, msg);
    }
};

pub const Base = struct {
    const Self = @This();

    pub fn publish(self: Self, msg: []const u8) void {
        _ = self;
        std.debug.print("some event pub: {s}\n", .{msg});
    }
};

pub const Weapon = struct {
    super: Base,
    const Self = @This();

    pub fn publishFn(ptr: *anyopaque, msg: []const u8) void {
        const self: *Weapon = @ptrCast(@alignCast(ptr));
        self.publish(msg);
    }

    pub fn publish(self: Self, msg: []const u8) void {
        self.super.publish(msg);
    }

    fn toIBase(self: *Self) IBase {
        return IBase{
            .ptr = self,
            .publishFn = publishFn,
        };
    }
};

pub fn testOop(allocator: std.mem.Allocator) !void {
    const wep = try allocator.create(Weapon);
    wep.publish("Hell yeah!");

    const baser = wep.toIBase();
    baser.publish("Fuck yeah!");
    std.process.exit(0);
}
