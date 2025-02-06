const std = @import("std");
const bitmasks = @import("bitmasks.zig");

/// bit-board based board representation
pub const BoardRep = struct {
    pieces: [12]u64,

    castle: u4,

    /// true => white's turn, false => black's turn
    to_move: bool,

    /// 0 => no enpassant, anything else => valid enpassant capture;
    enpassant: u6,

    ///Parses FEN into a board
    pub fn parseFen(fen: []const u8) FormatParseError!BoardRep {
        var iter = std.mem.splitScalar(u8, fen, ' ');

        const position = iter.next() orelse return error.MissingField;
        var pieces = [_]u64{0} ** 12;

        var index: u6 = 56;
        for (position) |c| {
            switch (c) {
                'P' => pieces[0] |= bitmasks.INDEX_MASKS[index],
                'N' => pieces[1] |= bitmasks.INDEX_MASKS[index],
                'B' => pieces[2] |= bitmasks.INDEX_MASKS[index],
                'R' => pieces[3] |= bitmasks.INDEX_MASKS[index],
                'Q' => pieces[4] |= bitmasks.INDEX_MASKS[index],
                'K' => pieces[5] |= bitmasks.INDEX_MASKS[index],

                'p' => pieces[6] |= bitmasks.INDEX_MASKS[index],
                'n' => pieces[7] |= bitmasks.INDEX_MASKS[index],
                'b' => pieces[8] |= bitmasks.INDEX_MASKS[index],
                'r' => pieces[9] |= bitmasks.INDEX_MASKS[index],
                'q' => pieces[10] |= bitmasks.INDEX_MASKS[index],
                'k' => pieces[11] |= bitmasks.INDEX_MASKS[index],

                '1' => {},
                '2' => index += 1,
                '3' => index += 2,
                '4' => index += 3,
                '5' => index += 4,
                '6' => index += 5,
                '7' => index += 6,
                '8' => index += 7,
                '/' => {
                    index &= ~@as(u6, 7);
                    if (index != 0) index -= 8;
                    continue;
                },
                else => return error.InvalidPosition,
            }
            if (index % 8 != 7) index += 1;
        }

        const to_move = switch ((iter.next() orelse return error.MissingField)[0]) {
            'w' => true,
            'b' => false,
            else => return error.NonExistentPlayer,
        };

        var castle: u4 = 0;
        for (iter.next() orelse return error.MissingField) |c| switch (c) {
            '-' => break,
            'K' => castle |= 0b0001,
            'Q' => castle |= 0b0010,
            'k' => castle |= 0b0100,
            'q' => castle |= 0b1000,
            else => return error.InvalidCastle,
        };

        const enpassant_str = iter.next() orelse return error.MissingField;

        const enpassant: u6 = if (enpassant_str[0] != '-') std.fmt.parseInt(u6, enpassant_str, 0) catch return error.EnpassantFormat else 0;

        return BoardRep{ .pieces = pieces, .castle = castle, .to_move = to_move, .enpassant = enpassant };
    }
};

const FormatParseError = error{
    MissingField,
    InvalidPosition,
    NonExistentPlayer,
    InvalidCastle,
    EnpassantFormat,
};
