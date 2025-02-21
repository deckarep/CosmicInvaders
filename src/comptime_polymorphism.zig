const std = @import("std");

pub const Enemy = union(enum) {
    ogre: Ogre,
    goblin: Goblin,
    troll: Troll,

    const Self = @This();

    pub fn attack(self: Self) void {
        // You can of course write this out for each branch.
        // switch (self) {
        //     .ogre => |o| {
        //         o.attack();
        //     },
        //     .goblin => |g| {
        //         g.attack();
        //     },

        // }

        // Or have the compiler do it!
        // inline style, have the compiler emit all switch branches.
        switch (self) {
            inline else => |baddie| {
                baddie.attack();
            },
        }
    }
};

pub const Troll = struct {
    const strength: u8 = 75;
    const Self = @This();

    pub fn attack(self: Self) void {
        _ = self;
        std.debug.print("Troll throws rock with a strengh of: {d}\n", .{strength});
    }
};

pub const Ogre = struct {
    strength: u8 = 100,
    const Self = @This();

    pub fn attack(self: Self) void {
        std.debug.print("Ogre rage attacks with a strengh of: {d}\n", .{self.strength});
    }
};

pub const Goblin = struct {
    strength: u8 = 25,
    items: [8]usize,
    const Self = @This();

    pub fn attack(self: Self) void {
        std.debug.print("Goblin shoots poision dart with a strengh of: {d}\n", .{self.strength});
    }
};

pub fn testCtpm(allocator: std.mem.Allocator) !void {
    _ = allocator;

    std.debug.print("sizeOf Ogre => {d}\n", .{@sizeOf(Ogre)});
    std.debug.print("sizeOf Troll => {d}\n", .{@sizeOf(Troll)});
    std.debug.print("sizeOf Goblin => {d}\n", .{@sizeOf(Goblin)});
    std.debug.print("sizeOf Enemy => {d}\n", .{@sizeOf(Enemy)});

    // Create the enemies.
    const a = Ogre{};
    const b = Ogre{};
    const c = Goblin{
        .items = [_]usize{9} ** 8,
    };
    const d = Troll{};

    // Add them to an array.
    var enemies = [4]Enemy{
        Enemy{ .ogre = a },
        Enemy{ .ogre = b },
        Enemy{ .goblin = c },
        Enemy{ .troll = d },
    };

    std.debug.print("sizeOf enemies => {d}\n", .{@sizeOf([4]Enemy)});

    // Iterate the enemies and attack!
    for (&enemies) |e| {
        e.attack();
    }

    std.process.exit(0);
}
