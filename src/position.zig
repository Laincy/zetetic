const std = @import("std");
const ArrayList = std.ArrayList;
const stdout = std.io.getStdOut().writer();

const bitmasks = @import("bitmasks.zig");

pub const Position = struct {
    pieces: [12]u64,
    /// QKqk
    castle: u4,
    enpassant: ?u6 = null,
    to_move: bool,

    const starting_position = Position{
        .pieces = .{ 0xff00, 0x42, 0x24, 0x81, 0x8, 0x10, 0xff000000000000, 0x4200000000000000, 0x2400000000000000, 0x8100000000000000, 0x800000000000000, 0x1000000000000000 },
        .castle = 0b1111,
        .enpassant = null,
        .to_move = true,
    };

    const PositionParseError = error{ ExceedsMaximumLength, MissingField, InvalidPosition, NonExistentPlayer, EnpassantFormat, InvalidCastle };

    /// parses a FEN string into its relevant position
    pub fn parseFen(fen: []const u8) PositionParseError!Position {
        if (fen.len > 92) return error.ExceedsMaximumLength;

        var iter = std.mem.splitScalar(u8, fen, ' ');

        const pieces = blk: {
            var index: u6 = 56;
            const position = iter.next() orelse return error.MissingField;

            var res = [_]u64{0} ** 12;

            for (position) |c| {
                switch (c) {
                    'P' => res[0] |= bitmasks.square_mask[index],
                    'N' => res[1] |= bitmasks.square_mask[index],
                    'B' => res[2] |= bitmasks.square_mask[index],
                    'R' => res[3] |= bitmasks.square_mask[index],
                    'Q' => res[4] |= bitmasks.square_mask[index],
                    'K' => res[5] |= bitmasks.square_mask[index],

                    'p' => res[6] |= bitmasks.square_mask[index],
                    'n' => res[7] |= bitmasks.square_mask[index],
                    'b' => res[8] |= bitmasks.square_mask[index],
                    'r' => res[9] |= bitmasks.square_mask[index],
                    'q' => res[10] |= bitmasks.square_mask[index],
                    'k' => res[11] |= bitmasks.square_mask[index],

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

            break :blk res;
        };

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

        const enpassant: ?u6 = if (enpassant_str[0] != '-') parseAlgebraic(enpassant_str) catch return error.EnpassantFormat else null;

        return .{ .pieces = pieces, .castle = castle, .to_move = to_move, .enpassant = enpassant };
    }

    fn makeMove(self: *Position, move: *const MoveFrame) void {
        self.pieces[move.piece_a.piece] ^= move.piece_a.changeBoard();
        if (move.piece_b != null) {
            self.pieces[move.piece_b.?.piece] ^= move.piece_b.?.changeBoard();

            if (move.piece_c != null) self.pieces[move.piece_c.?.piece] ^= move.piece_c.?.changeBoard();
        } else if (move.piece_a.piece == 0 and move.piece_a.origin >> 3 == 1 and (move.piece_a.target orelse 0) >> 3 == 3) {
            self.enpassant = move.piece_a.origin + 8;
        } else if (move.piece_a.piece == 6 and move.piece_a.origin >> 3 == 6 and move.piece_a.target orelse 0 >> 3 == 4) self.enpassant = move.piece_a.origin - 8;
    }

    fn unmakeMove(self: *Position, move: *const MoveFrame) void {
        self.pieces[move.piece_a.piece] ^= move.piece_a.changeBoard();
        if (move.piece_b != null) {
            self.pieces[move.piece_b.piece] ^= move.piece_b.changeBoard();

            if (move.piece_c != null) self.pieces[self.piece_c.piece] ^= move.piece_c.changeBoard();
        }

        self.enpassant = move.prev_enpassant;
    }

    /// Generates a set of all legal moves from a given position
    pub fn generateMoves(self: *const Position, allocator: std.mem.Allocator) !ArrayList(MoveFrame) {
        const moving_pieces = if (self.to_move) self.pieces[0..6] else self.pieces[6..];
        const target_pieces = if (self.to_move) self.pieces[6..] else self.pieces[0..6];

        const moving_mask = moving_pieces[0] | moving_pieces[1] | moving_pieces[2] | moving_pieces[3] | moving_pieces[4] | moving_pieces[5];
        const target_mask = target_pieces[0] | target_pieces[1] | target_pieces[2] | target_pieces[3] | target_pieces[4] | target_pieces[5];

        const board_mask = moving_mask | target_mask;

        var move_list = ArrayList(MoveFrame).init(allocator);

        {
            const king: u64 = moving_pieces[5];
            const king_index: u6 = @intCast(@ctz(king));
            var king_moves: u64 = bitmasks.king_move[king_index] & ~moving_mask;

            while (king_moves != 0) : (king_moves ^= bitmasks.square_mask[@ctz(king_moves)]) {
                const index: u6 = @intCast(@ctz(king_moves));
                const frame: ?MoveFrame = MoveFrame.generateNormal(self, 5, king_index, index);
                if (frame != null) try move_list.append(frame.?);
            }
            const castle_flags: u4 = if (self.to_move) self.castle & 0b11 else self.castle >> 2;
            const castle_k_mask: u64 = if (self.to_move) 0x60 else 0x6000000000000000;
            const castle_q_mask: u64 = if (self.to_move) 0x0e else 0xe00000000000000;

            if (castle_flags & 0b01 != 0 and board_mask & castle_k_mask == 0) {
                const frame = MoveFrame.generateCastle(self, false);
                if (frame != null) try move_list.append(frame.?);
            }
            if (castle_flags & 0b10 != 0 and board_mask & castle_q_mask == 0) {
                const frame = MoveFrame.generateCastle(self, true);
                if (frame != null) try move_list.append(frame.?);
            }
        }

        var queens: u64 = moving_pieces[4];
        while (queens != 0) : (queens ^= bitmasks.square_mask[@ctz(queens)]) {
            const queen_index: u6 = @intCast(@ctz(queens));
            var queen_moves: u64 = bitmasks.rook_mbb[queen_index].get(board_mask);
            queen_moves |= bitmasks.bishop_mbb[queen_index].get(board_mask);
            queen_moves &= ~moving_mask;

            while (queen_moves != 0) : (queen_moves ^= bitmasks.square_mask[@ctz(queen_moves)]) {
                const index: u6 = @intCast(@ctz(queen_moves));
                const frame = MoveFrame.generateNormal(self, if (self.to_move) 4 else 10, queen_index, index);
                if (frame != null) try move_list.append(frame.?);
            }
        }

        var rooks: u64 = moving_pieces[3];
        while (rooks != 0) : (rooks ^= bitmasks.square_mask[@ctz(rooks)]) {
            const rook_index: u6 = @intCast(@ctz(rooks));
            var rook_moves: u64 = bitmasks.rook_mbb[rook_index].get(board_mask) & ~moving_mask;

            while (rook_moves != 0) : (rook_moves ^= bitmasks.square_mask[@ctz(rook_moves)]) {
                const index: u6 = @intCast(@ctz(rook_moves));
                const frame = MoveFrame.generateNormal(self, if (self.to_move) 3 else 9, rook_index, index);
                if (frame != null) try move_list.append(frame.?);
            }
        }

        var bishops: u64 = moving_pieces[2];
        while (bishops != 0) : (bishops ^= bitmasks.square_mask[@ctz(bishops)]) {
            const bishop_index: u6 = @intCast(@ctz(bishops));
            var bishop_moves: u64 = bitmasks.bishop_mbb[bishop_index].get(board_mask) & ~moving_mask;

            while (bishop_moves != 0) : (bishop_moves ^= bitmasks.square_mask[@ctz(bishop_moves)]) {
                const index: u6 = @intCast(@ctz(bishop_moves));
                const frame = MoveFrame.generateNormal(self, if (self.to_move) 2 else 8, bishop_index, index);
                if (frame != null) try move_list.append(frame.?);
            }
        }

        var knights: u64 = moving_pieces[1];

        while (knights != 0) : (knights ^= bitmasks.square_mask[@ctz(knights)]) {
            const knight_index: u6 = @intCast(@ctz(knights));
            var knight_moves: u64 = bitmasks.knight_move[knight_index] & ~moving_mask;

            while (knight_moves != 0) : (knight_moves ^= bitmasks.square_mask[@ctz(knight_moves)]) {
                const index: u6 = @intCast(@ctz(knight_moves));
                const frame = MoveFrame.generateNormal(self, if (self.to_move) 1 else 7, knight_index, index);
                if (frame != null) try move_list.append(frame.?);
            }
        }

        var pawns: u64 = moving_pieces[0];

        while (pawns != 0) : (pawns ^= bitmasks.square_mask[@ctz(pawns)]) {
            const pawn_index: u6 = @intCast(@ctz(pawns));

            if (self.to_move) {
                var pawn_moves = bitmasks.square_mask[pawn_index] << 8;
                pawn_moves &= ~board_mask;
                if (pawn_index >> 3 == 1) {
                    pawn_moves |= pawn_moves << 8;
                    pawn_moves &= ~board_mask;
                }

                pawn_moves |= bitmasks.w_pawn_attack[pawn_index] & target_mask | (if (self.enpassant != null) bitmasks.square_mask[self.enpassant.?] else 0);

                while (pawn_moves != 0) : (pawn_moves ^= bitmasks.square_mask[@ctz(pawn_moves)]) {
                    const index: u6 = @intCast(@ctz(pawn_moves));
                    if (index >> 3 == 7) {
                        const frames: ?[4]MoveFrame = MoveFrame.generatePromotion(self, pawn_index, index);
                        if (frames != null) try move_list.appendSlice(frames.?[0..]);
                    } else {
                        const frame: ?MoveFrame = MoveFrame.generateNormal(self, 0, pawn_index, index);
                        if (frame != null) try move_list.append(frame.?);
                    }
                }
            } else {
                var pawn_moves = bitmasks.square_mask[pawn_index] >> 8;
                pawn_moves &= ~board_mask;
                if (pawn_index >> 3 == 6) {
                    pawn_moves |= pawn_moves >> 8;
                    pawn_moves &= ~board_mask;
                }

                pawn_moves |= bitmasks.b_pawn_attack[pawn_index] & target_mask;

                while (pawn_moves != 0) : (pawn_moves ^= bitmasks.square_mask[@ctz(pawn_moves)]) {
                    const index: u6 = @intCast(@ctz(pawn_moves));
                    if (index >> 3 == 0) {
                        const frames: ?[4]MoveFrame = MoveFrame.generatePromotion(self, pawn_index, index);
                        if (frames != null) try move_list.appendSlice(frames.?[0..]);
                    } else {
                        const frame: ?MoveFrame = MoveFrame.generateNormal(self, 6, pawn_index, index);
                        if (frame != null) try move_list.append(frame.?);
                    }
                }
            }
        }
        return move_list;
    }
};

fn parseAlgebraic(alg: []const u8) !u6 {
    if (alg.len != 2) return error.InvalidSquare;

    var index: u6 = switch (alg[0]) {
        'a' => 0,
        'b' => 1,
        'c' => 2,
        'd' => 3,
        'e' => 4,
        'f' => 5,
        'g' => 6,
        'h' => 7,
        else => return error.InvalidSquare,
    };
    index += ((std.fmt.parseInt(u6, alg[1..], 0) catch return error.InvalidSquare) - 1) << 3;

    return index;
}

/// stores a move so that it can be made and unmade, 24 bytes
pub const MoveFrame = struct {
    piece_a: SquareChange,
    piece_b: ?SquareChange = null,
    piece_c: ?SquareChange = null,

    prev_enpassant: ?u6,

    /// Evaluates if a move puts a king in an illegal position in O(1) time
    fn isLegal(self: *const MoveFrame, pos: *const Position) bool {
        var new_pos: Position = pos.*;
        new_pos.makeMove(self);

        const moving_pieces = if (new_pos.to_move) new_pos.pieces[0..6] else new_pos.pieces[6..];
        const target_pieces = if (new_pos.to_move) new_pos.pieces[6..] else new_pos.pieces[0..6];

        const moving_mask = moving_pieces[0] | moving_pieces[1] | moving_pieces[2] | moving_pieces[3] | moving_pieces[4] | moving_pieces[5];
        const target_mask = target_pieces[0] | target_pieces[1] | target_pieces[2] | target_pieces[3] | target_pieces[4] | target_pieces[5];
        const board_mask = moving_mask | target_mask;

        const king: u64 = target_pieces[5];
        const king_index: u6 = @intCast(@ctz(king));

        if (bitmasks.king_move[@ctz(moving_pieces[5])] & king != 0) return false;

        const vertical_pieces: u64 = moving_pieces[3] | moving_pieces[4];
        const vertical_mask: u64 = board_mask ^ vertical_pieces;

        var north: u64 = vertical_pieces & bitmasks.ray.north[king_index];
        if (north != 0) {
            north ^= bitmasks.ray.north[@ctz(north)];
            north &= vertical_mask;
            if (north == 0) return false;
        }

        var south: u64 = vertical_pieces & bitmasks.ray.south[king_index];
        if (south != 0) {
            south ^= bitmasks.ray.south[63 - @clz(south)];
            south &= vertical_mask;
            if (south == 0) return false;
        }

        var east: u64 = vertical_pieces & bitmasks.ray.east[king_index];
        if (east != 0) {
            east ^= bitmasks.ray.east[@ctz(east)];
            east &= vertical_mask;
            if (east == 0) return false;
        }

        var west: u64 = vertical_pieces & bitmasks.ray.east[king_index];
        if (west != 0) {
            west ^= bitmasks.ray.west[king_index];
            west &= vertical_mask;
            if (west == 0) return false;
        }

        const diagonal_pieces: u64 = moving_pieces[2] | moving_pieces[4];
        const diagonal_mask: u64 = board_mask ^ diagonal_pieces;

        var ne: u64 = diagonal_pieces & bitmasks.ray.north_east[king_index];
        // diagonal checks
        if (ne != 0) {
            ne ^= bitmasks.ray.north_east[@ctz(ne)];
            ne &= diagonal_mask;
            if (ne == 0) return false;
        }

        var se: u64 = diagonal_pieces & bitmasks.ray.south_east[king_index];
        if (se != 0) {
            se ^= bitmasks.ray.north_east[63 - @clz(se)];
            se &= diagonal_mask;
            if (se == 0) return false;
        }

        var nw: u64 = diagonal_pieces & bitmasks.ray.north_west[king_index];
        if (nw != 0) {
            nw ^= bitmasks.ray.north_west[@ctz(nw)];
            nw &= diagonal_mask;
            if (nw == 0) return false;
        }

        var sw: u64 = diagonal_pieces & bitmasks.ray.south_west[king_index];
        if (sw != 0) {
            sw ^= bitmasks.ray.south_west[63 - @clz(sw)];
            sw &= diagonal_mask;
            if (sw == 0) return false;
        }
        if (bitmasks.knight_move[king_index] & moving_pieces[1] != 0) return false;

        if (new_pos.to_move) {
            if (bitmasks.w_pawn_attack[king_index] & moving_pieces[0] != 0) return false;
        } else if (bitmasks.b_pawn_attack[king_index] & moving_pieces[0] != 0) return false;

        return true;
    }

    /// Generates a move frame, returns null if the move is not legal
    fn generateNormal(pos: *const Position, piece: u4, origin: u6, target: u6) ?MoveFrame {
        const target_pieces = if (pos.to_move) pos.pieces[6..] else pos.pieces[0..6];

        const target_mask = target_pieces[0] | target_pieces[1] | target_pieces[2] | target_pieces[3] | target_pieces[4] | target_pieces[5];
        const target_index: usize = if (pos.to_move) 0 else 6;

        var frame: MoveFrame = MoveFrame{ .piece_a = .{ .piece = piece, .origin = origin, .target = target }, .prev_enpassant = pos.enpassant };

        const target_a: u64 = bitmasks.square_mask[target];
        if (target_a & target_mask != 0) {
            for (target_index.., pos.pieces) |i, target_board| {
                if (target_board & target_a != 0) {
                    frame.piece_b = SquareChange{ .piece = @intCast(i), .origin = frame.piece_a.target.?, .target = null };
                    break;
                }
            }
        }

        if (frame.isLegal(pos)) return frame else return null;
    }

    /// Generates a move frame for a castle, returns null if the move is not legal
    fn generateCastle(pos: *const Position, side: bool) ?MoveFrame {
        if (pos.to_move) {
            const frame: MoveFrame = MoveFrame{
                .piece_a = .{ .piece = 5, .origin = 4, .target = if (side) 0 else 7 },
                .piece_b = .{ .piece = 3, .origin = if (side) 0 else 7, .target = if (side) 3 else 5 },
                .prev_enpassant = pos.enpassant,
            };

            if (frame.isLegal(pos)) return frame else return null;
        } else {
            const frame: MoveFrame = MoveFrame{
                .piece_a = .{ .piece = 11, .origin = 60, .target = if (side) 56 else 63 },
                .piece_b = .{ .piece = 9, .origin = if (side) 56 else 63, .target = if (side) 58 else 61 },
                .prev_enpassant = pos.enpassant,
            };

            if (frame.isLegal(pos)) return frame else return null;
        }
    }

    /// Generates moves for all promotion types
    fn generatePromotion(pos: *const Position, origin: u6, target: u6) ?[4]MoveFrame {
        var frame: MoveFrame = MoveFrame{
            .piece_a = .{ .piece = if (pos.to_move) 0 else 6, .origin = origin, .target = null },
            .piece_b = .{ .piece = if (pos.to_move) 1 else 7, .origin = target, .target = target },
            .prev_enpassant = pos.enpassant,
        };

        const target_pieces = if (pos.to_move) pos.pieces[6..] else pos.pieces[0..6];
        const target_index: usize = if (pos.to_move) 0 else 6;

        for (target_index.., target_pieces) |i, board| if (board & bitmasks.square_mask[target] != 0) {
            frame.piece_c = .{ .piece = @intCast(i), .origin = target, .target = null };
            break;
        };

        if (frame.isLegal(pos)) {
            var res = [_]MoveFrame{frame} ** 4;
            res[1].piece_b.?.piece += 1;
            res[2].piece_b.?.piece += 2;
            res[3].piece_b.?.piece += 3;
            return res;
        } else return null;
    }
};

/// the changes of a specific piece
pub const SquareChange = struct {
    piece: u4,
    origin: u6,
    target: ?u6,

    /// generates a board that can be XORd with the existing board to update it.
    inline fn changeBoard(self: *const SquareChange) u64 {
        var board = bitmasks.square_mask[self.origin];
        if (self.target != null) board |= bitmasks.square_mask[self.target.?];
        return board;
    }
};

const expect = std.testing.expect;
test "parse_fen" {
    const pos = try Position.parseFen("rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1");
    try expect(std.mem.eql(u64, &pos.pieces, &Position.starting_position.pieces));
    try expect(pos.castle == Position.starting_position.castle);
    try expect(pos.enpassant == Position.starting_position.enpassant);
    try expect(pos.to_move == Position.starting_position.to_move);
}

test "generate_first_move" {
    const pos = Position.starting_position;
    const res = try pos.generateMoves(std.testing.allocator);
    defer res.deinit();

    try expect(res.items.len == 20);
}
