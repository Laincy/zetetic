// Various debug utilities, should avoid importing any other files
const std = @import("std");
const stdout = std.io.getStdOut().writer();

/// Pretty print an individual Bitboard
pub fn printBitBoard(board: *const u64) !void {
    var buf: [576]u8 = ("  +---+---+---+---+---+---+---+---+\n" ** 16).*;
    for (0..8) |i| {
        var row: u8 = @intCast(board.* >> @intCast(8 * (7 - i)) & 0xFF);

        var encoded = [_]u8{' '} ** 8;
        while (row > 0) {
            const dist: u3 = @intCast(@ctz(row));
            encoded[dist] = 'x';
            row ^= @as(u8, 1) << dist;
        }
        _ = try std.fmt.bufPrint(buf[i * 72 ..], "{d} | {c} | {c} | {c} | {c} | {c} | {c} | {c} | {c} |\n", .{ (8 - i), encoded[0], encoded[1], encoded[2], encoded[3], encoded[4], encoded[5], encoded[6], encoded[7] });
    }

    try stdout.writeAll("  +---+---+---+---+---+---+---+---+\n" ++ buf ++ "    a   b   c   d   e   f   g   h\n");
}

pub fn printFullBoard(board: *const [12]u64) !void {
    var pieces: [12]u64 = board.*;
    var encoded = [_]u8{' '} ** 64;

    for (0..12) |i| {
        const encoded_char: u8 = switch (i) {
            0 => 'P',
            1 => 'N',

            2 => 'B',
            3 => 'R',
            4 => 'Q',
            5 => 'K',
            6 => 'p',
            7 => 'n',
            8 => 'b',
            9 => 'r',
            10 => 'q',
            11 => 'k',
            else => unreachable,
        };

        while (pieces[i] != 0) {
            const dist: u6 = @intCast(@ctz(pieces[i]));
            encoded[dist] = encoded_char;
            pieces[i] ^= @as(u64, 1) << dist;
        }
    }

    var buf = ("  +---+---+---+---+---+---+---+---+\n" ** 16).*;
    for (0..8) |i| {
        const row = encoded[(7 - i) << 3 ..];
        _ = try std.fmt.bufPrint(buf[i * 72 ..], "{d} | {c} | {c} | {c} | {c} | {c} | {c} | {c} | {c} |\n", .{ (8 - i), row[0], row[1], row[2], row[3], row[4], row[5], row[6], row[7] });
    }

    try stdout.writeAll("  +---+---+---+---+---+---+---+---+\n" ++ buf ++ "    a   b   c   d   e   f   g   h\n");
}
