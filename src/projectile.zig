const conf = @import("conf.zig");
const c = @import("cdefs.zig").c;
const state = @import("gamestate.zig");
const res = @import("resources.zig");

// pub const Projectile = struct {
//     fixedX: f32 = 0,
//     mX: f32 = 0,
//     mY: f32 = 0,

//     const Self = @This();

//     pub fn create(
//         x: f32,
//         y: f32,
//     ) Self {
//         return Self{
//             .fixedX = x,
//             .mY = y,
//         };
//     }

//     pub fn getBounds(self: Self) c.Rectangle {
//         const scale = 2.0;

//         return c.Rectangle{
//             .x = self.mX,
//             .y = self.mY,
//             .width = @as(f32, @floatFromInt(res.Resources.AlienBullet.width)) * scale,
//             .height = @as(f32, @floatFromInt(res.Resources.AlienBullet.height)) * scale,
//         };
//     }

//     pub fn update(self: *Self) void {
//         self.mY += conf.EnemyProjectileYSpeed;

//         const amplitude = 30.0;
//         const frequency = 1.0 / 15.0; // adjust this to get the desired period
//         self.mX = self.fixedX + amplitude * @sin(@as(f32, @floatFromInt(state.mGame.mTicks)) * frequency);
//     }
// };
