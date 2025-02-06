// Utility for calculating magic numbers
const std = @import("std");

const INDEX_MASKS = blk: {
    var board = [_]u64{0} ** 64;
    for (0..64) |i| board[i] = 0x1 << @intCast(i);
    break :blk board;
};

fn validate_rook(magic: u64, mask: u64, shift: u6, square: u6) !bool {
    var subset: u64 = 0;

    const n: usize = @as(usize, 1) << @intCast(@popCount(mask));

    var table = [_]u64{0xFFFF} ** 4096;

    while (true) {
        const key: u64 = (subset *% magic) >> shift;

        if (key > n - 1) return false;

        var bb: u64 = 0;
        // North
        for (0..7 - (square >> 3)) |i| {
            const square_mask = INDEX_MASKS[square] << @intCast(i * 8);
            if (subset & square_mask == 0) bb |= square_mask else break;
        }

        // South
        for (0..square >> 3) |i| {
            const square_mask = INDEX_MASKS[square] >> @intCast(i * 8);
            if (subset & square_mask == 0) bb |= square_mask else break;
        }

        // East
        for (0..7 - (square & 7)) |i| {
            const square_mask = INDEX_MASKS[square] << @intCast(i);
            if (subset & square_mask == 0) bb |= square_mask else break;
        }

        // West
        for (0..square & 7) |i| {
            const square_mask = INDEX_MASKS[square] >> @intCast(i);
            if (subset & square_mask == 0) bb |= square_mask else break;
        }

        bb ^= INDEX_MASKS[square];

        if (table[key] == 0xFFFF) table[key] = bb else if (table[key] != bb) return false;

        subset = (subset -% mask) & mask;
        if (subset == 0) break;
    }
    return true;
}

pub fn generate_rook_magics(masks: [64]u64) !struct { magics: [64]u64, shifts: [64]u6 } {
    var magics = [_]u64{0} ** 64;
    var shifts = [_]u6{0} ** 64;

    var prng = std.rand.DefaultPrng.init(blk: {
        var seed: u64 = undefined;
        try std.posix.getrandom(std.mem.asBytes(&seed));
        break :blk seed;
    });

    const rand = prng.random();

    for (0.., masks) |i, mask| {
        const indicies = @popCount(mask);
        shifts[i] = @intCast(64 - indicies);

        var magic = rand.int(u64) & rand.int(u64) & rand.int(u64);
        while (true) : (magic = rand.int(u64) & rand.int(u64) & rand.int(u64)) {
            if (try validate_rook(magic, mask, shifts[i], @intCast(i))) {
                magics[i] = magic;
                break;
            }
        }
    }

    return .{ .magics = magics, .shifts = shifts };
}

pub fn generate_bishop_magics(masks: [64]u64) !struct { magics: [64]u64, shifts: [64]u6 } {
    var magics = [_]u64{0} ** 64;
    var shifts = [_]u6{0} ** 64;

    var prng = std.rand.DefaultPrng.init(blk: {
        var seed: u64 = undefined;
        try std.posix.getrandom(std.mem.asBytes(&seed));
        break :blk seed;
    });

    const rand = prng.random();

    for (0.., masks) |i, mask| {
        const indicies = @popCount(mask);
        shifts[i] = @intCast(64 - indicies);

        var magic = rand.int(u64) & rand.int(u64) & rand.int(u64);
        while (true) : (magic = rand.int(u64) & rand.int(u64) & rand.int(u64)) {
            if (try validate_bishop(magic, mask, shifts[i], @intCast(i))) {
                magics[i] = magic;
                break;
            }
        }
    }

    return .{ .magics = magics, .shifts = shifts };
}

fn validate_bishop(magic: u64, mask: u64, shift: u6, square: u6) !bool {
    var subset: u64 = 0;

    const n: usize = @as(usize, 1) << @intCast(@popCount(mask));

    var table = [_]u64{0xFF} ** 4096;

    while (true) {
        const key: u64 = (subset *% magic) >> shift;

        if (key > n - 1) return false;

        var bb: u64 = 0;

        const south = square >> 3;
        const north = 7 - south;
        const west = square & 7;
        const east = 7 - west;

        for (0..@min(north, east)) |j| {
            const square_mask = INDEX_MASKS[square] << @intCast(j * 9);
            if (subset & square_mask == 0) bb |= square_mask else break;
        }

        for (0..@min(south, east)) |j| {
            const square_mask = INDEX_MASKS[square] >> @intCast(j * 7);
            if (subset & square_mask == 0) bb |= square_mask else break;
        }

        for (0..@min(north, west)) |j| {
            const square_mask = INDEX_MASKS[square] << @intCast(j * 7);
            if (subset & square_mask == 0) bb |= square_mask else break;
        }

        for (0..@min(south, west)) |j| {
            const square_mask = INDEX_MASKS[square] >> @intCast(j * 9);
            if (subset & square_mask == 0) bb |= square_mask else break;
        }

        bb ^= INDEX_MASKS[square];

        if (table[key] == 0xFF) table[key] = bb else if (table[key] != bb) return false;

        subset = (subset -% mask) & mask;
        if (subset == 0) break;
    }
    return true;
}
