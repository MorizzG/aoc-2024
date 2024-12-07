const std = @import("std");

const utils = @import("lib/utils.zig");

const filename = "inputs/day4.txt";

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();

    {
        const file_reader = try utils.FileReader.init(alloc, filename);
        defer file_reader.deinit();

        const result = try part1(alloc, file_reader.reader());

        try std.io.getStdOut().writer().print("Day 4, part 1: {}\n", .{result});
    }

    {
        const file_reader = try utils.FileReader.init(alloc, filename);
        defer file_reader.deinit();

        const result = try part2(alloc, file_reader.reader());

        try std.io.getStdOut().writer().print("Day 4, part 2: {}\n", .{result});
    }
}

fn check(grid: []const []const u8, needle: []const u8, i: usize, j: usize, i_step: usize, j_step: usize) bool {
    var idx = i;
    var jdx = j;

    for (0..needle.len) |n| {
        if (grid[idx][jdx] != needle[n]) {
            return false;
        }

        idx +%= i_step;
        jdx +%= j_step;
    }

    return true;
}

fn part1(alloc: std.mem.Allocator, reader: anytype) !u32 {
    const input = try reader.readAllAlloc(alloc, std.math.maxInt(usize));
    defer alloc.free(input);

    // number of lines in number of newline + 1
    // except if the last line is empty, then one less
    var num_lines = std.mem.count(u8, input, "\n") + 1;
    if (input[input.len - 1] == '\n') {
        num_lines -= 1;
    }

    const grid = try alloc.alloc([]const u8, num_lines);
    defer alloc.free(grid);

    // var it = std.mem.splitScalar(u8, input, '\n');
    var it = std.mem.tokenizeScalar(u8, input, '\n');

    const line_length = it.peek().?.len;

    for (grid) |*grid_line| {
        const line = it.next().?;

        std.debug.assert(line.len == line_length);

        grid_line.* = line;
    }

    std.debug.assert(it.next() == null);

    const xmas = "XMAS";
    const samx = "SAMX";

    var count: u32 = 0;

    for (0..num_lines) |i| {
        for (0..line_length - 3) |j| {
            if (check(grid, xmas, i, j, 0, 1)) {
                count += 1;
            } else if (check(grid, samx, i, j, 0, 1)) {
                count += 1;
            }
        }
    }

    for (0..line_length) |j| {
        for (0..num_lines - 3) |i| {
            if (check(grid, xmas, i, j, 1, 0)) {
                count += 1;
            } else if (check(grid, samx, i, j, 1, 0)) {
                count += 1;
            }
        }
    }

    for (0..num_lines - 3) |i| {
        for (0..line_length - 3) |j| {
            if (check(grid, xmas, i, j, 1, 1)) {
                count += 1;
            } else if (check(grid, samx, i, j, 1, 1)) {
                count += 1;
            }

            if (check(grid, xmas, i, j + 3, 1, std.math.maxInt(usize))) {
                count += 1;
            } else if (check(grid, samx, i, j + 3, 1, std.math.maxInt(usize))) {
                count += 1;
            }
        }
    }

    return count;
}

fn part2(alloc: std.mem.Allocator, reader: anytype) !u32 {
    const input = try reader.readAllAlloc(alloc, std.math.maxInt(usize));
    defer alloc.free(input);

    // number of lines in number of newline + 1
    // except if the last line is empty, then one less
    var num_lines = std.mem.count(u8, input, "\n") + 1;
    if (input[input.len - 1] == '\n') {
        num_lines -= 1;
    }

    const grid = try alloc.alloc([]const u8, num_lines);
    defer alloc.free(grid);

    // var it = std.mem.splitScalar(u8, input, '\n');
    var it = std.mem.tokenizeScalar(u8, input, '\n');

    const line_length = it.peek().?.len;

    for (grid) |*grid_line| {
        const line = it.next().?;

        std.debug.assert(line.len == line_length);

        grid_line.* = line;
    }

    std.debug.assert(it.next() == null);

    const mas = "MAS";
    const sam = "SAM";

    var count: u32 = 0;

    for (0..num_lines - 2) |i| {
        for (0..line_length - 2) |j| {
            if (check(grid, sam, i, j, 1, 1) or check(grid, mas, i, j, 1, 1)) {
                if (check(grid, sam, i, j + 2, 1, std.math.maxInt(usize)) or check(grid, mas, i, j + 2, 1, std.math.maxInt(usize))) {
                    count += 1;
                }
            }
        }
    }

    return count;
}

test "part1 example" {
    const alloc = std.testing.allocator;

    const example =
        \\MMMSXXMASM
        \\MSAMXMSMSA
        \\AMXSXMAAMM
        \\MSAMASMSMX
        \\XMASAMXAMM
        \\XXAMMXXAMA
        \\SMSMSASXSS
        \\SAXAMASAAA
        \\MAMMMXMMMM
        \\MXMXAXMASX
    ;

    var stream = std.io.fixedBufferStream(example);

    const result = try part1(alloc, stream.reader());

    try std.testing.expectEqual(18, result);
}

test "part1 input" {
    const alloc = std.testing.allocator;

    const file_reader = try utils.FileReader.init(alloc, filename);
    defer file_reader.deinit();

    const result = try part1(alloc, file_reader.reader());

    try std.testing.expectEqual(2593, result);
}

test "part2 example" {
    const alloc = std.testing.allocator;

    const example =
        \\MMMSXXMASM
        \\MSAMXMSMSA
        \\AMXSXMAAMM
        \\MSAMASMSMX
        \\XMASAMXAMM
        \\XXAMMXXAMA
        \\SMSMSASXSS
        \\SAXAMASAAA
        \\MAMMMXMMMM
        \\MXMXAXMASX
    ;

    var stream = std.io.fixedBufferStream(example);

    const result = try part2(alloc, stream.reader());

    try std.testing.expectEqual(9, result);
}

test "part2 input" {
    const alloc = std.testing.allocator;

    const file_reader = try utils.FileReader.init(alloc, filename);
    defer file_reader.deinit();

    const result = try part2(alloc, file_reader.reader());

    try std.testing.expectEqual(1950, result);
}
