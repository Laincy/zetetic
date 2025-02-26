const std = @import("std");
const stdout = std.io.getStdOut().writer();

const Position = @import("position.zig").Position;

pub fn main() !void {
    const args = try std.process.argsAlloc(std.heap.page_allocator);
    defer std.process.argsFree(std.heap.page_allocator, args);

    if (args.len < 2) return error.ExpectedArgument;

    const pos = try Position.parseFen(args[1]);
    const moves = try pos.generateMoves(std.heap.page_allocator);
    defer moves.deinit();

    try stdout.print("legal moves found: {d}\n", .{moves.items.len});
}
