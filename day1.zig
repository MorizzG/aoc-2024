const std = @import("std");

const utils = @import("utils.zig");

pub fn main() !void {
    // // Prints to stderr (it's a shortcut based on `std.io.getStdErr()`)
    // std.debug.print("All your {s} are belong to us.\n", .{"codebase"});

    // // stdout is for the actual output of your application, for example if you
    // // are implementing gzip, then only the compressed bytes should be sent to
    // // stdout, not any debugging messages.
    // const stdout_file = std.io.getStdOut().writer();
    // var bw = std.io.bufferedWriter(stdout_file);
    // const stdout = bw.writer();

    // try stdout.print("Run `zig build test` to run the tests.\n", .{});

    // try bw.flush(); // don't forget to flush!

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();

    const filename = "inputs/day1.txt";

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

fn rangeConst(comptime n: usize) [n]usize {
    var array: [n]usize = undefined;

    for (0.., &array) |i, *elem| {
        elem.* = i;
    }

    return array;
}

fn range(alloc: std.mem.Allocator, n: usize) ![]usize {
    var array = try alloc.alloc(usize, n);

    for (0..n) |i| {
        array[i] = i;
    }

    return array;
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

    const left_idxs = try range(alloc, num_lines);
    const right_idxs = try range(alloc, num_lines);
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

    try std.testing.expect(result == 11);
}

test "part1 input" {
    const alloc = std.testing.allocator;

    const filename = "inputs/day1.txt";

    const file_reader = try utils.FileReader.init(alloc, filename);
    defer file_reader.deinit();

    const result = try part1(alloc, file_reader.reader());

    try std.testing.expect(result == 1506483);
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

    try std.testing.expect(result == 31);
}

test "part2 input" {
    const alloc = std.testing.allocator;

    const filename = "inputs/day1.txt";

    const file_reader = try utils.FileReader.init(alloc, filename);
    defer file_reader.deinit();

    const result = try part2(alloc, file_reader.reader());

    try std.testing.expect(result == 23126924);
}
