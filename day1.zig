const std = @import("std");

const utils = @import("lib/utils.zig");

const filename = "inputs/day1.txt";

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();

    {
        const file_reader = try utils.FileReader.init(alloc, filename);
        defer file_reader.deinit();

        const result = try part1(alloc, file_reader.reader());

        try std.io.getStdOut().writer().print("Day 1, part 1: {}\n", .{result});
    }

    {
        const file_reader = try utils.FileReader.init(alloc, filename);
        defer file_reader.deinit();

        const result = try part2(alloc, file_reader.reader());

        try std.io.getStdOut().writer().print("Day 1, part 1: {}\n", .{result});
    }
}

fn argsort_cmp(comptime T: type, comptime lessThanFn: fn (ctx: void, lhs: T, rhs: T) bool) (fn ([]const T, usize, usize) bool) {
    return struct {
        fn cmp(array: []const T, left_idx: usize, right_idx: usize) bool {
            return lessThanFn({}, array[left_idx], array[right_idx]);
        }
    }.cmp;
}

fn part1(alloc: std.mem.Allocator, reader: anytype) !u64 {
    var left_list = std.ArrayList(u32).init(alloc);
    var right_list = std.ArrayList(u32).init(alloc);
    defer left_list.deinit();
    defer right_list.deinit();

    var line_reader = utils.lineReader(alloc, reader);
    defer line_reader.deinit();

    while (try line_reader.next()) |line| {
        var number_parser = utils.numberParser(u32, line);

        const left = (try number_parser.next()).?;
        const right = (try number_parser.next()).?;

        std.debug.assert((try number_parser.next()) == null);

        try left_list.append(left);
        try right_list.append(right);
    }

    const num_lines = left_list.items.len;

    std.debug.assert(right_list.items.len == num_lines);

    const left_idxs = try utils.range(alloc, num_lines);
    const right_idxs = try utils.range(alloc, num_lines);
    defer alloc.free(left_idxs);
    defer alloc.free(right_idxs);

    std.debug.assert(left_list.items.len == left_idxs.len);
    std.debug.assert(right_list.items.len == right_idxs.len);

    for (0..num_lines) |i| {
        std.debug.assert(left_idxs[i] == i);
        std.debug.assert(right_idxs[i] == i);
    }

    const cmp = argsort_cmp(u32, std.sort.asc(u32));

    std.mem.sort(usize, left_idxs, left_list.items, cmp);
    std.mem.sort(usize, right_idxs, right_list.items, cmp);

    for (0..(num_lines - 1)) |i| {
        std.debug.assert(left_list.items[left_idxs[i]] <= left_list.items[left_idxs[i + 1]]);
        std.debug.assert(right_list.items[right_idxs[i]] <= right_list.items[right_idxs[i + 1]]);
    }

    var sum: u64 = 0;

    for (left_idxs, right_idxs) |left_idx, right_idx| {
        sum += @abs(@as(i64, left_list.items[left_idx]) - @as(i64, right_list.items[right_idx]));
    }

    return sum;
}

fn part2(alloc: std.mem.Allocator, reader: anytype) !u64 {
    var left_list = std.ArrayList(u32).init(alloc);
    defer left_list.deinit();

    var right_map = std.AutoHashMap(u32, u32).init(alloc);
    defer right_map.deinit();

    var line_reader = utils.lineReader(alloc, reader);
    defer line_reader.deinit();

    while (try line_reader.next()) |line| {
        var number_parser = utils.numberParser(u32, line);

        const left = (try number_parser.next()).?;
        const right = (try number_parser.next()).?;

        try left_list.append(left);

        if (right_map.get(right)) |count| {
            try right_map.put(right, count + 1);
        } else {
            try right_map.put(right, 1);
        }
    }

    var sum: u64 = 0;

    for (left_list.items) |x| {
        if (right_map.get(x)) |count| {
            sum += count * x;
        }
    }

    return sum;
}

test "part1 example" {
    const alloc = std.testing.allocator;

    const example =
        \\3   4
        \\4   3
        \\2   5
        \\1   3
        \\3   9
        \\3   3
    ;

    var stream = std.io.fixedBufferStream(example);

    const result = try part1(alloc, stream.reader());

    try std.testing.expectEqual(11, result);
}

test "part1 input" {
    const alloc = std.testing.allocator;

    const file_reader = try utils.FileReader.init(alloc, filename);
    defer file_reader.deinit();

    const result = try part1(alloc, file_reader.reader());

    try std.testing.expectEqual(1506483, result);
}

test "part2 example" {
    const alloc = std.testing.allocator;

    const example =
        \\3   4
        \\4   3
        \\2   5
        \\1   3
        \\3   9
        \\3   3
    ;

    var stream = std.io.fixedBufferStream(example);

    const result = try part2(alloc, stream.reader());

    try std.testing.expectEqual(31, result);
}

test "part2 input" {
    const alloc = std.testing.allocator;

    const file_reader = try utils.FileReader.init(alloc, filename);
    defer file_reader.deinit();

    const result = try part2(alloc, file_reader.reader());

    try std.testing.expectEqual(23126924, result);
}
