const std = @import("std");
const stdout = std.io.getStdOut().writer();

const Position = @import("position.zig").Position;

const evaluate = @import("eval.zig").evaluate;

pub fn main() !void {
    const args = try std.process.argsAlloc(std.heap.page_allocator);
    defer std.process.argsFree(std.heap.page_allocator, args);

    if (args.len < 2) return error.ExpectedArgument;

    const pos = try Position.parseFen(args[1]);
    const moves = try pos.generateMoves(std.heap.page_allocator);
    defer moves.deinit();

    try stdout.print("legal moves found: {d}\n", .{moves.items.len});

    var best_val: i16 = undefined;

    for ()

    try stdout.print("evaluation {d}\n", .{evaluate(&pos)});
}
