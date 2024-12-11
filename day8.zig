const std = @import("std");

const utils = @import("lib/utils.zig");

const spice = @import("lib/spice.zig");

const day = "8";

const filename = "inputs/day" ++ day ++ ".txt";

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();

    {
        const file_reader = try utils.FileReader.init(alloc, filename);
        defer file_reader.deinit();

        const result = try part1(alloc, file_reader.reader());

        try std.io.getStdOut().writer().print("Day " ++ day ++ ", part 1: {}\n", .{result});
    }

    {
        const file_reader = try utils.FileReader.init(alloc, filename);
        defer file_reader.deinit();

        const result = try part2(alloc, file_reader.reader());

        try std.io.getStdOut().writer().print("Day " ++ day ++ ", part 2: {}\n", .{result});
    }
}

fn part1(alloc: std.mem.Allocator, reader: anytype) !u64 {
    const Pos = struct {
        x: usize,
        y: usize,
    };

    var arena = std.heap.ArenaAllocator.init(alloc);
    defer arena.deinit();

    var freq_pos = std.AutoHashMap(u8, std.ArrayList(Pos)).init(arena.allocator());
    defer freq_pos.deinit();

    var line_reader = utils.lineReader(alloc, reader);
    defer line_reader.deinit();

    var x_size: usize = 0;
    var y_size: usize = 0;

    while (try line_reader.next()) |line| : (x_size += 1) {
        if (line.len == 0) {
            break;
        }

        if (y_size == 0) {
            y_size = line.len;
        } else {
            std.debug.assert(y_size == line.len);
        }

        for (0.., line) |y, c| {
            if (c != '.') {
                const entry = try freq_pos.getOrPut(c);

                const pos_list = entry.value_ptr;

                if (!entry.found_existing) {
                    pos_list.* = std.ArrayList(Pos).init(arena.allocator());
                }

                try pos_list.append(.{ .x = x_size, .y = y });
            }
        }
    }

    const antinodes = try utils.allocGridInit(bool, alloc, x_size, y_size, false);
    defer utils.deinitGrid(bool, alloc, antinodes);

    for (antinodes) |line| {
        for (line) |b| {
            std.debug.assert(b == false);
        }
    }

    var it = freq_pos.iterator();

    while (it.next()) |entry| {
        const pos_list = entry.value_ptr.items;
        const n = pos_list.len;

        for (0..n) |i| {
            const pos_i = pos_list[i];

            for (0..i) |j| {
                const pos_j = pos_list[j];

                const diff_x = pos_i.x -% pos_j.x;
                const diff_y = pos_i.y -% pos_j.y;

                const antinode1_x = pos_i.x +% diff_x;
                const antinode1_y = pos_i.y +% diff_y;

                if (antinode1_x < x_size and antinode1_y < y_size) {
                    antinodes[antinode1_x][antinode1_y] = true;
                }

                const antinode2_x = pos_j.x -% diff_x;
                const antinode2_y = pos_j.y -% diff_y;

                if (antinode2_x < x_size and antinode2_y < y_size) {
                    antinodes[antinode2_x][antinode2_y] = true;
                }
            }
        }
    }

    var antinode_count: u64 = 0;

    for (antinodes) |line| {
        for (line) |b| {
            if (b) {
                antinode_count += 1;
            }
        }
    }

    return antinode_count;
}

fn part2(alloc: std.mem.Allocator, reader: anytype) !u64 {
    const Pos = struct {
        x: usize,
        y: usize,
    };

    var arena = std.heap.ArenaAllocator.init(alloc);
    defer arena.deinit();

    var freq_pos = std.AutoHashMap(u8, std.ArrayList(Pos)).init(arena.allocator());
    defer freq_pos.deinit();

    var line_reader = utils.lineReader(alloc, reader);
    defer line_reader.deinit();

    var x_size: usize = 0;
    var y_size: usize = 0;

    while (try line_reader.next()) |line| : (x_size += 1) {
        if (line.len == 0) {
            break;
        }

        if (y_size == 0) {
            y_size = line.len;
        } else {
            std.debug.assert(y_size == line.len);
        }

        for (0.., line) |y, c| {
            if (c != '.') {
                const entry = try freq_pos.getOrPut(c);

                const pos_list = entry.value_ptr;

                if (!entry.found_existing) {
                    pos_list.* = std.ArrayList(Pos).init(arena.allocator());
                }

                try pos_list.append(.{ .x = x_size, .y = y });
            }
        }
    }

    const antinodes = try utils.allocGridInit(bool, alloc, x_size, y_size, false);
    defer utils.deinitGrid(bool, alloc, antinodes);

    for (antinodes) |line| {
        for (line) |b| {
            std.debug.assert(b == false);
        }
    }

    var it = freq_pos.iterator();

    while (it.next()) |entry| {
        const pos_list = entry.value_ptr.items;
        const n = pos_list.len;

        for (0..n) |i| {
            const pos_i = pos_list[i];

            for (0..i) |j| {
                const pos_j = pos_list[j];

                const i_minus_j_x = pos_i.x -% pos_j.x;
                const i_minus_j_y = pos_i.y -% pos_j.y;

                {
                    var antinode_x = pos_i.x;
                    var antinode_y = pos_i.y;

                    while (antinode_x < x_size and antinode_y < y_size) {
                        antinodes[antinode_x][antinode_y] = true;

                        antinode_x +%= i_minus_j_x;
                        antinode_y +%= i_minus_j_y;
                    }
                }

                {
                    var antinode_x = pos_j.x;
                    var antinode_y = pos_j.y;

                    while (antinode_x < x_size and antinode_y < y_size) {
                        antinodes[antinode_x][antinode_y] = true;

                        antinode_x -%= i_minus_j_x;
                        antinode_y -%= i_minus_j_y;
                    }
                }
            }
        }
    }

    var antinode_count: u64 = 0;

    for (antinodes) |line| {
        for (line) |b| {
            if (b) {
                antinode_count += 1;
            }
        }
    }

    return antinode_count;
}

test "part1 example" {
    const alloc = std.testing.allocator;

    const example =
        \\............
        \\........0...
        \\.....0......
        \\.......0....
        \\....0.......
        \\......A.....
        \\............
        \\............
        \\........A...
        \\.........A..
        \\............
        \\............
    ;

    var stream = std.io.fixedBufferStream(example);

    const result = try part1(alloc, stream.reader());

    try std.testing.expectEqual(14, result);
}

test "part1 input" {
    const alloc = std.testing.allocator;

    const file_reader = try utils.FileReader.init(alloc, filename);
    defer file_reader.deinit();

    const result = try part1(alloc, file_reader.reader());

    try std.testing.expectEqual(381, result);
}

test "part2 example" {
    const alloc = std.testing.allocator;

    const example =
        \\............
        \\........0...
        \\.....0......
        \\.......0....
        \\....0.......
        \\......A.....
        \\............
        \\............
        \\........A...
        \\.........A..
        \\............
        \\............
    ;

    var stream = std.io.fixedBufferStream(example);

    const result = try part2(alloc, stream.reader());

    try std.testing.expectEqual(34, result);
}

test "part2 input" {
    const alloc = std.testing.allocator;

    const file_reader = try utils.FileReader.init(alloc, filename);
    defer file_reader.deinit();

    const result = try part2(alloc, file_reader.reader());

    try std.testing.expectEqual(1184, result);
}
