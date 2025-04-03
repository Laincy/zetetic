const std = @import("std");
const Position = @import("position.zig").Position;
const bitmasks = @import("bitmasks.zig");

/// Used for material value evaluation, should be vertically symmetric
const PieceSquare = struct {
    early: [64]i16,
    late: ?[64]i16 = null,
    base: i16,

    const early_mv: i16 = 8000;
    const late_mv: i16 = 1500;

    fn snapLerp(self: *const PieceSquare, mv: i16, square: u6) i16 {
        if (mv <= PieceSquare.early_mv or self.late == null) return self.early[square];

        if (self.late != null) {
            if (mv >= PieceSquare.late_mv) return self.late.?[square];
            // LERP where y = weight and x = material value
            var res: i16 = self.early[square] * (PieceSquare.late_mv - mv) + self.late.?[square] * (PieceSquare.early_mv - mv);
            res = @divFloor(res, PieceSquare.early_mv - PieceSquare.late_mv);

            return self.base + res;
        } else return self.base + self.early[square];
    }
};

const piece_squares: [6]PieceSquare = .{
    PieceSquare{ // Pawns, arbitralily trying to keep some pawns back to protect king
        .base = 100,
        .early = .{
            0,  0,  0,   0,   0,   0,   0,  0,
            30, 30, 40,  40,  40,  30,  30, 30,
            10, 10, 15,  30,  30,  15,  10, 10,
            5,  5,  5,   10,  10,  5,   5,  5,
            0,  0,  0,   0,   0,   0,   0,  0,
            5,  -5, -10, 0,   0,   -10, -5, 5,
            5,  10, 10,  -20, -20, 10,  10, 5,
            0,  0,  0,   0,   0,   0,   0,  0,
        },
        .late = .{
            0,  0,  0,  0,  0,  0,  0,  0,
            40, 40, 40, 40, 40, 40, 40, 40,
            30, 30, 30, 30, 30, 30, 30, 30,
            20, 20, 20, 20, 20, 20, 20, 20,
            10, 10, 10, 10, 10, 10, 10, 10,
            5,  5,  5,  5,  5,  5,  5,  5,
            0,  0,  0,  0,  0,  0,  0,  0,
            0,  0,  0,  0,  0,  0,  0,  0,
        },
    },
    PieceSquare{ // Knights, try to keep towards center of board for higher mobility
        .base = 350,
        .early = .{
            -10, -5, 0,  0,  0,  0,  -5, -10,
            -5,  0,  5,  5,  5,  5,  0,  -5,
            0,   5,  10, 10, 10, 10, 5,  0,
            0,   5,  10, 15, 15, 10, 5,  0,
            0,   5,  10, 15, 15, 10, 5,  0,
            0,   5,  10, 10, 10, 10, 5,  0,
            -5,  0,  5,  5,  5,  5,  0,  -5,
            -10, -5, 0,  0,  0,  0,  -5, -10,
        },
    },
    PieceSquare{ // Bishops, try to control center
        .base = 350,
        .early = .{
            -15, -10, -5, -5, -5, -5, -5,  -15,
            -10, 0,   0,  0,  0,  0,  0,   -10,
            -5,  0,   10, 10, 10, 10, 0,   -5,
            -5,  0,   10, 15, 15, 10, 0,   0,
            -5,  0,   10, 15, 15, 10, 0,   0,
            -5,  0,   10, 10, 10, 10, 0,   -5,
            -10, 0,   0,  0,  0,  0,  0,   -10,
            -15, -10, 0,  0,  0,  0,  -10, -15,
        },
    },
    PieceSquare{ // Rooks, keep central and benefeit castle
        .base = 425,
        .early = .{
            0,  -5, -5, -5, -5, -5, -5, 0,
            -5, 0,  0,  0,  0,  0,  0,  -5,
            -5, 0,  0,  0,  0,  0,  0,  -5,
            -5, 0,  0,  15, 15, 0,  0,  -5,
            -5, 0,  5,  10, 10, 5,  0,  -5,
            -5, 5,  10, 10, 10, 10, 5,  -5,
            -5, 10, 10, 10, 10, 10, 10, -5,
            0,  0,  0,  10, 10, 0,  0,  0,
        },
    },
    PieceSquare{ // Queens, keep central
        .base = 1000,
        .early = .{
            -20, -10, -10, -10, -10, -10, -10, -20,
            -5,  0,   0,   0,   0,   0,   0,   -10,
            -5,  0,   5,   5,   5,   5,   0,   -5,
            -5,  0,   5,   10,  10,  5,   0,   -5,
            0,   0,   5,   10,  10,  5,   0,   0,
            -5,  0,   5,   5,   5,   5,   0,   -5,
            -10, 0,   0,   0,   0,   0,   0,   -10,
            -20, -10, -5,  -5,  -5,  -5,  -10, -20,
        },
    },
    PieceSquare{ // Kings, keep back in early game then support in late game
        .base = 0,
        .early = .{
            -65, -70, -70, -75, -75, -70, -70, -65,
            -55, -60, -60, -65, -65, -60, -60, -55,
            -45, -50, -50, -55, -55, -50, -50, -45,
            -35, -40, -40, -45, -45, -40, -40, -35,
            -25, -30, -30, -35, -35, -30, -25, -25,
            -15, -20, -20, -20, -20, -20, -20, -15,
            20,  15,  0,   -5,  -5,  0,   15,  20,
            25,  15,  10,  5,   5,   10,  15,  25,
        },
        .late = .{
            -10, -5,  -5,  -5,  -5,  -5,  -5,  -10,
            -5,  0,   0,   0,   0,   0,   0,   -5,
            -5,  0,   0,   0,   0,   0,   0,   -5,
            -5,  0,   0,   5,   5,   0,   0,   -5,
            -5,  0,   0,   5,   5,   0,   0,   -5,
            -5,  0,   0,   0,   0,   0,   0,   -5,
            -30, -25, 0,   0,   0,   0,   -25, -30,
            -40, -30, -30, -30, -30, -30, -30, -40,
        },
    },
};

/// Transfor s a black piece to be from white perspective for use with piece square tables
inline fn perspective(square: u6) u6 {
    return square ^ 0b111000;
}

/// Evaluates a position. Positive values favor white, negative values favor black
pub fn evaluate(pos: *const Position) i16 {
    // Checks for checkmate
    if (pos.pieces[5] == 0) return -32767 else if (pos.pieces[11] == 0) return 32767;

    var value: i16 = 0;

    // Calculates raw material value of the board, ignores king value
    const material: i16 = (100 * @as(i16, @popCount(pos.pieces[0] | pos.pieces[6]))) + (350 * @as(i16, @popCount(pos.pieces[1] | pos.pieces[7] | pos.pieces[2] | pos.pieces[8]))) + (525 * @as(i16, @popCount(pos.pieces[3] | pos.pieces[9]))) + (1000 * @as(i16, @popCount(pos.pieces[4] | pos.pieces[10])));

    // White piece-square values
    for (0.., pos.pieces[0..6]) |i, board| {
        var board_mut: u64 = board;
        while (board_mut != 0) : (board_mut ^= bitmasks.square_mask[@ctz(board_mut)]) {
            const square: u6 = @intCast(@ctz(board_mut));
            value += piece_squares[i].snapLerp(material, square);
        }
    }

    // Black piece-square values
    for (0.., pos.pieces[6..]) |i, board| {
        var board_mut: u64 = board;
        while (board_mut != 0) : (board_mut ^= bitmasks.square_mask[@ctz(board_mut)]) {
            var square: u6 = @intCast(@ctz(board_mut));
            square ^= 0b111000;
            value -= piece_squares[i].snapLerp(material, square);
        }
    }

    return value;
}
