// pre-generated bitmasks and other bitboard utilities

/// masks for squares 0-63 on a bitboard
pub const square_mask: [64]u64 = blk: {
    var res: [64]u64 = undefined;
    for (0..64) |i| res[i] = 0x1 << @intCast(i);
    break :blk res;
};

pub const w_pawn_move: [64]u64 = blk: {
    var res: [64]u64 = [_]u64{0} ** 64;

    const double: u64 = 0x10100;
    for (8..16) |i| res[i] = double << @intCast(i);

    const single: u64 = 0x100;
    for (16..56) |i| res[i] = single << @intCast(i);

    break :blk res;
};

pub const b_pawn_move: [64]u64 = blk: {
    var res: [64]u64 = [_]u64{0} ** 64;

    const double: u64 = 0x80800000000000;
    for (48..56) |i| res[i] = double >> @intCast(63 - i);

    const single: u64 = 0x80000000000000;
    for (8..48) |i| res[i] = single >> @intCast(63 - i);

    break :blk res;
};

pub const w_pawn_attack: [64]u64 = blk: {
    var res: [64]u64 = [_]u64{0} ** 64;
    const base: u64 = 0x280;
    for (8..56) |i| {
        res[i] |= base << @intCast(i);
        res[i] &= 0xff << (8 * ((i >> 3) + 1));
    }
    break :blk res;
};

pub const b_pawn_attack: [64]u64 = blk: {
    var res: [64]u64 = [_]u64{0} ** 64;
    const base: u64 = 0x140000000000000;
    for (8..56) |i| {
        res[i] |= base >> @intCast(63 - i);
        res[i] &= 0xff << (8 * ((i >> 3) - 1));
    }
    break :blk res;
};

pub const knight_move = blk: {
    var res: [64]u64 = [_]u64{0} ** 64;
    const base: u64 = 0xa1100110a; // Centered at 18
    for (0..64) |i| {
        switch (i) {
            0...17 => res[i] = base >> @intCast(18 - i),
            18 => res[18] = base,
            else => res[i] = base << @intCast(i - 18),
        }
        if (i & 7 <= 2) res[i] &= 0xf0f0f0f0f0f0f0f else if (i & 7 >= 6) res[i] &= 0xf0f0f0f0f0f0f0f0;
    }
    break :blk res;
};

pub const king_move = blk: {
    var res: [64]u64 = undefined;
    const base: u64 = 0x20502; // Centered at 9
    for (0..64) |i| {
        switch (i) {
            0...8 => res[i] = base >> @intCast(9 - i),
            9 => res[9] = base,
            else => res[i] = base << @intCast(i - 9),
        }

        if (i & 7 == 0) res[i] &= 0x303030303030303 else if (i & 7 == 7) res[i] &= 0xc0c0c0cc0c0c0c0;
    }
    break :blk res;
};

pub const MagicBitBoard = struct {
    arr: []const u64,
    mask: u64,
    magic: u64,
    shift: u6,

    /// fetches the movement bitboard, treats all pieces as capturable
    pub fn get(self: *const MagicBitBoard, occ: u64) u64 {
        const pre = self.mask & occ;
        const key = (pre *% self.magic) >> self.shift;
        return self.arr[key];
    }
};

pub const ray = struct {
    pub const north: [64]u64 = blk: {
        var res: [64]u64 = undefined;
        for (0..64) |i| res[i] = @as(u64, 0x0101010101010100) << @intCast(i);
        break :blk res;
    };

    pub const south: [64]u64 = blk: {
        var res: [64]u64 = undefined;
        for (0..64) |i| res[i] = 0x0080808080808080 >> @intCast(63 - i);
        break :blk res;
    };

    pub const east: [64]u64 = blk: {
        var res: [64]u64 = undefined;
        for (0..64) |i| {
            var tmp = 0xfe << @intCast(i);
            tmp &= 0xff << (8 * (i >> 3));
            res[i] = tmp;
        }
        break :blk res;
    };

    pub const west: [64]u64 = blk: {
        var res: [64]u64 = undefined;
        for (0..64) |i| {
            var tmp = 0x7f00000000000000 >> @intCast(63 - i);
            tmp &= 0xff << (8 * (i >> 3));
            res[i] = tmp;
        }
        break :blk res;
    };

    pub const north_east: [64]u64 = blk: {
        var res: [64]u64 = [_]u64{0} ** 64;
        for (0..64) |i| {
            const n: usize = 7 - (i >> 3);
            const e: usize = 7 - (i & 7);

            const ne: usize = @min(n, e);
            if (ne != 0) {
                for (1..ne + 1) |j| res[i] |= square_mask[i] << @intCast(j * 9);
            }
        }
        break :blk res;
    };

    pub const south_east: [64]u64 = blk: {
        var res: [64]u64 = [_]u64{0} ** 64;
        for (0..64) |i| {
            const s: usize = i >> 3;
            const e: usize = 7 - (i & 7);

            const se: usize = @min(s, e);
            if (se != 0) {
                for (1..se + 1) |j| res[i] |= square_mask[i] >> @intCast(j * 7);
            }
        }
        break :blk res;
    };

    pub const north_west: [64]u64 = blk: {
        var res: [64]u64 = [_]u64{0} ** 64;
        for (0..64) |i| {
            const n: usize = 7 - (i >> 3);
            const w: usize = i & 7;

            const nw: usize = @min(n, w);
            if (nw != 0) {
                for (1..nw + 1) |j| res[i] |= square_mask[i] << @intCast(j * 7);
            }
        }
        break :blk res;
    };

    pub const south_west: [64]u64 = blk: {
        var res: [64]u64 = [_]u64{0} ** 64;
        for (0..64) |i| {
            const s: usize = i >> 3;
            const w: usize = i & 7;

            const sw: usize = @min(s, w);
            if (sw != 0) {
                for (1..sw + 1) |j| res[i] |= square_mask[i] >> @intCast(j * 9);
            }
        }
        break :blk res;
    };
};

pub const rook_mbb: [64]MagicBitBoard = blk: {
    const rook_shifts: [64]u6 = [_]u6{ //fmt.skip
        52, 53, 53, 53, 53, 53, 53, 52, 53, 54, 54, 54, 54, 54, 54, 53,
        53, 54, 54, 54, 54, 54, 54, 53, 53, 54, 54, 54, 54, 54, 54, 53,
        53, 54, 54, 54, 54, 54, 54, 53, 53, 54, 54, 54, 54, 54, 54, 53,
        53, 54, 54, 54, 54, 54, 54, 53, 52, 53, 53, 53, 53, 53, 53, 52,
    };
    const rook_magics: [64]u64 = [_]u64{ //fmt.skip
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

    var res: [64]MagicBitBoard = undefined;
    for (0..64) |i| {
        const magic: u64 = rook_magics[i];
        const shift: u6 = rook_shifts[i];

        var mask = ray.north[i] | ray.south[i] | ray.east[i] | ray.west[i];

        var arr = [_]u64{0xFF} ** (@as(usize, 1) << @intCast(64 - @as(usize, shift)));

        arr[0] = mask;

        if (i & 7 != 0) mask &= 0xfefefefefefefefe;
        if (i & 7 != 7) mask &= 0x7f7f7f7f7f7f7f7f;

        if (i >> 3 != 0) mask &= 0xffffffffffffff00;
        if (i >> 3 != 7) mask &= 0x00ffffffffffffff;

        var subset: u64 = (0 -% mask) & mask;

        @setEvalBranchQuota(1000000);
        while (subset != 0) : (subset = (subset -% mask) & mask) {
            const key = (subset *% magic) >> shift;
            if (key > arr.len - 1) @compileError("invalid rook magics or shifts");

            var bb = arr[0];

            const north: u64 = subset & ray.north[i];
            if (north != 0) bb ^= ray.north[@ctz(north)];

            const south: u64 = subset & ray.south[i];
            if (south != 0) bb ^= ray.south[63 - @clz(south)];

            const east: u64 = subset & ray.east[i];
            if (east != 0) bb ^= ray.east[@ctz(east)];

            const west: u64 = subset & ray.west[i];
            if (west != 0) bb ^= ray.east[63 - @clz(west)];

            if (arr[key] == 0xFF) arr[key] = bb else if (arr[key] != bb) @compileError("invalid rook magics or shifts");
        }

        res[i] = MagicBitBoard{ .arr = &[0]u64{} ++ arr, .mask = mask, .magic = magic, .shift = shift };
    }
    break :blk res;
};

pub const bishop_mbb: [64]MagicBitBoard = blk: {
    const bishop_shifts: [64]u6 = [_]u6{ //fmt.skip
        58, 59, 59, 59, 59, 59, 59, 58, 59, 59, 59, 59, 59, 59, 59, 59,
        59, 59, 57, 57, 57, 57, 59, 59, 59, 59, 57, 55, 55, 57, 59, 59,
        59, 59, 57, 55, 55, 57, 59, 59, 59, 59, 57, 57, 57, 57, 59, 59,
        59, 59, 59, 59, 59, 59, 59, 59, 58, 59, 59, 59, 59, 59, 59, 58,
    };

    const bishop_magics: [64]u64 = [_]u64{ //fmt.skip
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

    var res: [64]MagicBitBoard = undefined;

    for (0..64) |i| {
        const magic: u64 = bishop_magics[i];
        const shift: u6 = bishop_shifts[i];

        var mask = ray.north_east[i] | ray.south_east[i] | ray.north_west[i] | ray.south_west[i];

        var arr = [_]u64{0xFF} ** (@as(usize, 1) << @intCast(64 - @as(usize, shift)));

        arr[0] = mask;

        mask &= 0x7e7e7e7e7e7e00;

        var subset: u64 = (0 -% mask) & mask;

        @setEvalBranchQuota(1000000);
        while (subset != 0) : (subset = (subset -% mask) & mask) {
            const key = (subset *% magic) >> shift;
            if (key > arr.len - 1) @compileError("invalid bishop magics or shifts");

            var bb = arr[0];

            const north_east = subset & ray.north_east[i];
            if (north_east != 0) bb ^= ray.north_east[@ctz(north_east)];

            const south_east = subset & ray.south_east[i];
            if (south_east != 0) bb ^= ray.south_east[63 - @clz(south_east)];

            const north_west = subset & ray.north_west[i];
            if (north_west != 0) bb ^= ray.north_west[@ctz(north_west)];

            const south_west = subset & ray.south_west[i];
            if (south_west != 0) bb ^= ray.south_west[63 - @clz(south_west)];

            if (arr[key] == 0xFF) arr[key] = bb else if (arr[key] != bb) @compileError("invalid bishop magics or shifts");
        }

        res[i] = MagicBitBoard{ .arr = &[0]u64{} ++ arr, .mask = mask, .magic = magic, .shift = shift };
    }

    break :blk res;
};
