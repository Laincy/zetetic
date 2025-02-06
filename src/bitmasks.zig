// Compile-time calculated bitmasks
pub const W_PAWN_ATTACKS = blk: {
    const att_mask: u64 = 0b101;
    var board = [_]u64{0} ** 64;
    board[8] = 0x20000;
    for (9..56) |i| {
        board[i] = (att_mask << ((i - 1) & 0x7) & 0xFF) << (8 * ((i >> 3) + 1));
    }
    break :blk board;
};

pub const B_PAWN_ATTACKS = blk: {
    const att_mask: u64 = 0b101;
    var board = [_]u64{0} ** 64;
    board[8] = 0x2;
    for (9..56) |i| {
        board[i] = (att_mask << ((i - 1) & 0x7) & 0xFF) << (8 * ((i / 8) - 1));
    }
    break :blk board;
};
pub const KNIGHT_MOVES = blk: {
    var board = [_]u64{0} ** 64;
    const att_mask: u64 = 0xa1100110a; // Centered at 18
    for (0..64) |i| switch (i) {
        0...17 => board[i] = att_mask >> @intCast(18 - i),
        18 => board[18] = att_mask,
        else => board[i] = att_mask << @intCast(i - 18),
    };
    break :blk board;
};
pub const KING_MOVES = blk: {
    var board = [_]u64{0} ** 64;
    const att_mask: u64 = 0x20502; // Centered at 9
    for (0..64) |i| {
        switch (i) {
            0...8 => board[i] = att_mask >> @intCast(9 - i),
            9 => board[9] = att_mask,
            else => board[i] = att_mask << @intCast(i - 9),
        }

        switch (i & 0x7) {
            0 => board[i] &= 0x303030303030303,
            7 => board[i] &= 0xc0c0c0cc0c0c0c0,
            else => {},
        }
    }

    break :blk board;
};

const INDEX_MASKS = blk: {
    var board = [_]u64{0} ** 64;
    for (0..64) |i| board[i] = 0x1 << @intCast(i);
    break :blk board;
};

pub const BISHOP_MOVES = blk: {
    var board = INDEX_MASKS;
    for (0..64) |i| {
        const south = i >> 3;
        const north = 7 - south;
        const west = i & 7;
        const east = 7 - west;

        var ne: u6 = @min(north, east);
        if (ne != 0) ne += 1;

        for (0..ne) |j| board[i] |= INDEX_MASKS[i] << @intCast(j * 9);

        var se: u6 = @min(south, east);
        if (se != 0) se += 1;

        for (0..se) |j| board[i] |= INDEX_MASKS[i] >> @intCast(j * 7);

        var nw: u6 = @min(north, west);
        if (nw != 0) nw += 1;

        for (0..nw) |j| board[i] |= INDEX_MASKS[i] << @intCast(j * 7);

        var sw: u6 = @min(south, west);
        if (sw != 0) sw += 1;

        for (0..sw) |j| board[i] |= INDEX_MASKS[i] >> @intCast(j * 9);

        board[i] ^= INDEX_MASKS[i];
    }
    break :blk board;
};
pub const ROOK_MOVES = blk: {
    var board = INDEX_MASKS;
    const vert: u64 = 0x101010101010101;
    const horiz: u64 = 0xFF;

    for (0..64) |i| {
        const col: u6 = i & 7;
        const row: u6 = i >> 3;

        board[i] |= (vert << col) | (horiz << (row << 3));
        board[i] ^= INDEX_MASKS[i];
    }
    break :blk board;
};

pub const BISHOP_PRE = blk: {
    var board = INDEX_MASKS;
    for (0..64) |i| {
        const south = i >> 3;
        const north = 7 - south;
        const west = i & 7;
        const east = 7 - west;

        const ne: u6 = @min(north, east);
        for (0..ne) |j| board[i] |= INDEX_MASKS[i] << @intCast(j * 9);

        const se: u6 = @min(south, east);
        for (0..se) |j| board[i] |= INDEX_MASKS[i] >> @intCast(j * 7);

        const nw: u6 = @min(north, west);
        for (0..nw) |j| board[i] |= INDEX_MASKS[i] << @intCast(j * 7);

        const sw: u6 = @min(south, west);
        for (0..sw) |j| board[i] |= INDEX_MASKS[i] >> @intCast(j * 9);

        board[i] ^= INDEX_MASKS[i];
    }
    break :blk board;
};

pub const ROOK_PRE = blk: {
    var board = INDEX_MASKS;
    const vert: u64 = 0x1010101010100;
    const horiz: u64 = 0x7E;

    for (0..64) |i| {
        const col: u6 = i & 7;
        const row: u6 = i >> 3;

        board[i] |= (vert << col) | (horiz << (row << 3));
        board[i] ^= INDEX_MASKS[i];
    }
    break :blk board;
};

pub const ROOK_ATTACKS: [64]MagicBitBoard = blk: {
    var res: [64]MagicBitBoard = undefined;
    var index: usize = 0;
    for (0.., ROOK_PRE) |i, mask| {
        const n: usize = index + (@as(usize, 1) << @popCount(mask));
        res[i] = MagicBitBoard{ .table = ROOK_ATTACK_RAW[index..n], .mask = mask, .magic = ROOK_MAGICS[i], .shift = ROOK_SHIFTS[i] };
        index = n;
    }
    break :blk res;
};

pub const BISHOP_ATTACKS: [64]MagicBitBoard = blk: {
    var res: [64]MagicBitBoard = undefined;
    var index: usize = 0;
    for (0.., BISHOP_PRE) |i, mask| {
        const n: usize = index + (@as(usize, 1) << @popCount(mask));
        res[i] = MagicBitBoard{ .table = BISHOP_ATTACK_RAW[index..n], .mask = mask, .magic = BISHOP_MAGICS[i], .shift = BISHOP_SHIFTS[i] };
        index = n;
    }
    break :blk res;
};

const ROOK_SHIFTS: [64]u6 = [_]u6{ //fmt.skip
    52, 53, 53, 53, 53, 53, 53, 52, 53, 54, 54, 54, 54, 54, 54, 53,
    53, 54, 54, 54, 54, 54, 54, 53, 53, 54, 54, 54, 54, 54, 54, 53,
    53, 54, 54, 54, 54, 54, 54, 53, 53, 54, 54, 54, 54, 54, 54, 53,
    53, 54, 54, 54, 54, 54, 54, 53, 52, 53, 53, 53, 53, 53, 53, 52,
};
const ROOK_MAGICS: [64]u64 = [_]u64{ //fmt.skip
    648536215552827648,  594475288256057346,   36081573719711744,
    324264155335884928,  1224984596337168418,  1873499646291152900,
    72058186743677184,   9403525367827804416,  7208152080681320448,
    2612439628805836803, 2635168801766899744,  9570226519673152,
    72339146391683328,   563018815635460,      1154188692043076096,
    9224638676397474048, 4647719488406421568,  10376577216166264896,
    288267760901947520,  141288183713792,      2342294568587760643,
    2815300638606336,    21990333321224,       10995133153364,
    1297107067869601920, 153122569870901632,   282647509073984,
    144123990614474880,  2882309263371339776,  720857454010827776,
    653127086876720,     1154087029882503297,  423586862989416,
    9301219384255062016, 12682277906647359488, 76578788023994368,
    4917943989383989250, 4620763655816945676,  288248346630422914,
    2310628125978919050, 18049857767899141,    76561486261534720,
    2269392536633472,    9368051004388016144,  285907399802928,
    437412165482315856,  1168366632994,        599236005724212,
    150651348845056,     9390023090167087168,  9514136512968069376,
    76562843066962048,   18018798713438336,    576601506971779200,
    3463285740027491328, 1970333431137536,     288793876133716234,
    4629742200527323330, 576471748495642754,   9233787229474670597,
    18577383092396042,   281509537776137,      609191083309632004,
    9332025776599482754,
};

const ROOK_ATTACK_RAW = blk: {
    var result: []const u64 = &[0]u64{};

    for (0.., ROOK_PRE) |i, mask| {
        var att_table = [_]u64{0xFF} ** (@as(usize, 1) << @popCount(mask));

        const magic = ROOK_MAGICS[i];
        const shift = ROOK_SHIFTS[i];
        var subset = 0;
        @setEvalBranchQuota(10000000);
        while (true) {
            const key = (subset *% magic) >> shift;

            if (key > att_table.len - 1) @compileError("invalid rook magics or shifts");

            var bb: u64 = 0;
            // North
            for (0..7 - (i >> 3)) |j| {
                const square_mask = INDEX_MASKS[i] << @intCast(j * 8);
                if (subset & square_mask == 0) bb |= square_mask else break;
            }

            // South
            for (0..i >> 3) |j| {
                const square_mask = INDEX_MASKS[i] >> @intCast(j * 8);
                if (subset & square_mask == 0) bb |= square_mask else break;
            }

            // East
            for (0..7 - (i & 7)) |j| {
                const square_mask = INDEX_MASKS[i] << @intCast(j);
                if (subset & square_mask == 0) bb |= square_mask else break;
            }

            // West
            for (0..i & 7) |j| {
                const square_mask = INDEX_MASKS[i] >> @intCast(j);
                if (subset & square_mask == 0) bb |= square_mask else break;
            }

            bb ^= INDEX_MASKS[i];

            if (att_table[key] == 0xFF) att_table[key] = bb else if (att_table[key] != bb) @compileError("Invalid rooks");

            subset = (subset -% mask) & mask;
            if (subset == 0) break;
        }
        result = result ++ att_table;
    }
    break :blk result;
};

const BISHOP_ATTACK_RAW = blk: {
    var result: []const u64 = &[0]u64{};
    for (0.., BISHOP_PRE) |i, mask| {
        var att_table = [_]u64{0xFF} ** (@as(usize, 1) << @popCount(mask));

        const magic = BISHOP_MAGICS[i];
        const shift = BISHOP_SHIFTS[i];
        var subset = 0;
        @setEvalBranchQuota(10000000);
        while (true) {
            const key = (subset *% magic) >> shift;

            if (key > att_table.len - 1) @compileError("invalid bishop magics or shifts");

            var bb: u64 = 0;

            const south = i >> 3;
            const north = 7 - south;
            const west = i & 7;
            const east = 7 - west;

            for (0..@min(north, east)) |j| {
                const square_mask = INDEX_MASKS[i] << @intCast(j * 9);
                if (subset & square_mask == 0) bb |= square_mask else break;
            }

            for (0..@min(south, east)) |j| {
                const square_mask = INDEX_MASKS[i] >> @intCast(j * 7);
                if (subset & square_mask == 0) bb |= square_mask else break;
            }

            for (0..@min(north, west)) |j| {
                const square_mask = INDEX_MASKS[i] << @intCast(j * 7);
                if (subset & square_mask == 0) bb |= square_mask else break;
            }

            for (0..@min(south, west)) |j| {
                const square_mask = INDEX_MASKS[i] >> @intCast(j * 9);
                if (subset & square_mask == 0) bb |= square_mask else break;
            }

            bb ^= INDEX_MASKS[i];

            if (att_table[key] == 0xFF) att_table[key] = bb else if (att_table[key] != bb) @compileError("invalid bishop magics or shifts");

            subset = (subset -% mask) & mask;
            if (subset == 0) break;
        }
        result = result ++ att_table;
    }
    break :blk result;
};

const BISHOP_SHIFTS: [64]u6 = [_]u6{ //fmt.skip
    58, 59, 59, 59, 59, 59, 59, 58, 59, 59, 59, 59, 59, 59, 59, 59,
    59, 59, 57, 57, 57, 57, 59, 59, 59, 59, 57, 55, 55, 57, 59, 59,
    59, 59, 57, 55, 55, 57, 59, 59, 59, 59, 57, 57, 57, 57, 59, 59,
    59, 59, 59, 59, 59, 59, 59, 59, 58, 59, 59, 59, 59, 59, 59, 58,
};

const BISHOP_MAGICS: [64]u64 = [_]u64{ //fmt.skip
    13546329066209571,    5233184021277606404, 73193406880563200,
    11549516704850006272, 1190080740248782880, 595049122189844480,
    9597164690866368,     577868275935875072,  1143638264448008,
    4611690450868519424,  144190126673695282,  4613383690230693888,
    18050752186425348,    4791915843007319106, 649174759105372160,
    1199083555439915008,  2265131527455116,    20829165590809600,
    588845685642887178,   1126406731988992,    9440671820561776928,
    281475782550533,      4613093549071684608, 4616260021762917376,
    1218304250286096,     20270596915234176,   2308103914425434624,
    285877364588672,      145523662492286976,  577023839730405376,
    288813126239977744,   578854500828446852,  10137772189028364,
    41104220541161984,    1143801465018368,    11547273459413420544,
    4510205287079945,     6773011525993089,    1804255154766481409,
    1173760024771231808,  74312212105170980,   71485704708098,
    13548252205953032,    4647714953287959296, 3945052183200773,
    144414324029456768,   24842537550218816,   569822991622656,
    1603856031091275776,  864871461315166208,  2468023244269289472,
    144137180523266177,   293296994620409890,  4899920930400175268,
    290517515254235144,   586602690574819338,  1200667789103168,
    36170086420066306,    25824469504,         9229001673845262336,
    9241953784205156864,  9224779431150092800, 72063111527924229,
    616995560710341186,
};

pub const MagicBitBoard = struct {
    table: []const u64, //2 ^ n length slice within a precomputed function
    mask: u64,
    magic: u64,
    shift: u6, // 63 - n

    fn retrieve(self: *const MagicBitBoard, occ: u64) u64 {
        var key: u64 = occ & self.mask;
        key *= self.magic;
        key >>= self.shift;

        return self.table[key].*;
    }
};
