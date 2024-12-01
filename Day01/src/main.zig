const std = @import("std");

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

    try part1(alloc);
    try part2(alloc);
}

fn range(comptime n: u32) [n]usize {
    var array: [n]usize = undefined;

    for (0.., &array) |i, *elem| {
        elem.* = i;
    }

    return array;
}

fn argsort_cmp(comptime T: type, comptime lessThanFn: fn (ctx: void, lhs: T, rhs: T) bool) (fn ([]T, usize, usize) bool) {
    return struct {
        fn cmp(array: []T, left_idx: usize, right_idx: usize) bool {
            return lessThanFn({}, array[left_idx], array[right_idx]);
        }
    }.cmp;
}

fn part1(alloc: std.mem.Allocator) !void {
    const filename = "input1.txt";

    const num_lines = 1_000;

    const file = try std.fs.cwd().openFile(filename, .{});
    defer file.close();

    var left_list: [num_lines]u32 = undefined;
    var right_list: [num_lines]u32 = undefined;

    const file_reader = file.reader();
    var buf_reader = std.io.BufferedReader(4096, @TypeOf(file_reader)){ .unbuffered_reader = file_reader };

    const reader = std.io.Reader(@TypeOf(&buf_reader), std.fs.File.Reader.Error, @TypeOf(buf_reader).read){ .context = &buf_reader };

    var line_buf = std.ArrayList(u8).init(alloc);
    defer line_buf.deinit();

    for (0..(num_lines + 1)) |i| {
        reader.streamUntilDelimiter(line_buf.writer(), '\n', 4096) catch |err| switch (err) {
            error.EndOfStream => break,
            else => return err,
        };

        const left = try std.fmt.parseUnsigned(u32, line_buf.items[0..5], 10);
        const right = try std.fmt.parseUnsigned(u32, line_buf.items[8..13], 10);

        left_list[i] = left;
        right_list[i] = right;

        try line_buf.resize(0);
    }

    var left_idxs = range(num_lines);
    var right_idxs = range(num_lines);

    std.debug.assert(left_list.len == left_idxs.len);
    std.debug.assert(right_list.len == right_idxs.len);

    for (0..1000) |i| {
        std.debug.assert(left_idxs[i] == i);
        std.debug.assert(right_idxs[i] == i);
    }

    const cmp = argsort_cmp(u32, std.sort.asc(u32));

    std.mem.sort(usize, &left_idxs, @as([]u32, &left_list), cmp);
    std.mem.sort(usize, &right_idxs, @as([]u32, &right_list), cmp);

    for (0..(num_lines - 1)) |i| {
        std.debug.assert(left_list[left_idxs[i]] <= left_list[left_idxs[i + 1]]);
        std.debug.assert(right_list[right_idxs[i]] <= right_list[right_idxs[i + 1]]);
    }

    var sum: u64 = 0;

    for (left_idxs, right_idxs) |left_idx, right_idx| {
        sum += @abs(@as(i64, left_list[left_idx]) - @as(i64, right_list[right_idx]));
    }

    std.debug.print("Day 1, part 1: {}\n", .{sum});
}

fn part2(alloc: std.mem.Allocator) !void {
    const filename = "input1.txt";

    const num_lines = 1_000;

    const file = try std.fs.cwd().openFile(filename, .{});
    defer file.close();

    var left_list: [num_lines]u32 = undefined;

    var right_map = std.AutoHashMap(u32, u32).init(alloc);
    defer right_map.deinit();

    const file_reader = file.reader();
    var buf_reader = std.io.BufferedReader(4096, @TypeOf(file_reader)){ .unbuffered_reader = file_reader };

    const reader = std.io.Reader(@TypeOf(&buf_reader), std.fs.File.Reader.Error, @TypeOf(buf_reader).read){ .context = &buf_reader };

    var line_buf = std.ArrayList(u8).init(alloc);
    defer line_buf.deinit();

    for (0..(num_lines + 1)) |i| {
        reader.streamUntilDelimiter(line_buf.writer(), '\n', 4096) catch |err| switch (err) {
            error.EndOfStream => break,
            else => return err,
        };

        const left = try std.fmt.parseUnsigned(u32, line_buf.items[0..5], 10);
        const right = try std.fmt.parseUnsigned(u32, line_buf.items[8..13], 10);

        left_list[i] = left;

        if (right_map.get(right)) |count| {
            try right_map.put(right, count + 1);
        } else {
            try right_map.put(right, 1);
        }

        try line_buf.resize(0);
    }

    var sum: u64 = 0;

    for (left_list) |x| {
        if (right_map.get(x)) |count| {
            sum += count * x;
        }
    }

    std.debug.print("Day 1, part 2: {}\n", .{sum});
}
