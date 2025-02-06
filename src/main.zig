const std = @import("std");
const bitmasks = @import("bitmasks.zig");
const magic = @import("util/magic_numbers.zig");

pub fn main() !void {
    _ = try magic.generate_rook_magics(bitmasks.ROOK_PRE);
    _ = try magic.generate_bishop_magics(bitmasks.BISHOP_PRE);
}
