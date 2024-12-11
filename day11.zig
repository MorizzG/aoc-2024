const std = @import("std");

const utils = @import("lib/utils.zig");

const spice = @import("lib/spice.zig");

const day = "11";

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

const CacheKey = struct { n: u64, depth: u8 };

fn countStones(n: u64, remaining_depth: u8, cache: *std.AutoHashMap(CacheKey, u64)) u64 {
    if (remaining_depth == 0) {
        return 1;
    }

    if (cache.get(.{ .n = n, .depth = remaining_depth })) |result| {
        return result;
    }

    if (n == 0) {
        const result = countStones(1, remaining_depth - 1, cache);
        cache.put(.{ .n = n, .depth = remaining_depth }, result) catch @panic("cache put failed");

        return result;
        // try countStones(count, 1, remaining_depth);
        // return;
    }

    if (utils.num_digits(n) % 2 == 0) {
        const num_digits = utils.num_digits(n);

        const pow10 = std.math.powi(u32, 10, num_digits / 2) catch @panic("powi failed");

        const left = n / pow10;
        const right = n % pow10;

        // return countStones(left, remaining_depth - 1, cache) + countStones(right, remaining_depth - 1, cache);

        const left_result = countStones(left, remaining_depth - 1, cache);
        const right_result = countStones(right, remaining_depth - 1, cache);

        const result = left_result + right_result;

        cache.put(.{ .n = n, .depth = remaining_depth }, result) catch @panic("cache put failed");

        return left_result + right_result;

        // try countStones(count, left, remaining_depth - 1);
        // try countStones(count, right, remaining_depth - 1);
        // return;
    }

    const result = countStones(n * 2024, remaining_depth - 1, cache);
    cache.put(.{ .n = n, .depth = remaining_depth }, result) catch @panic("cache put failed");

    return result;

    // try countStones(count, 2024 * n, remaining_depth - 1);
}

fn part1(alloc: std.mem.Allocator, reader: anytype) !u64 {
    const input = try reader.readAllAlloc(alloc, std.math.maxInt(usize));
    defer alloc.free(input);

    var count: u64 = 0;

    var cache = std.AutoHashMap(CacheKey, u64).init(alloc);
    defer cache.deinit();

    var number_parser = utils.numberParser(u64, input);

    while (try number_parser.next()) |n| {
        count += countStones(n, 25, &cache);
    }

    return count;
}

fn part2(alloc: std.mem.Allocator, reader: anytype) !u64 {
    const input = try reader.readAllAlloc(alloc, std.math.maxInt(usize));
    defer alloc.free(input);

    var count: u64 = 0;

    var cache = std.AutoHashMap(CacheKey, u64).init(alloc);
    defer cache.deinit();

    var number_parser = utils.numberParser(u64, input);

    while (try number_parser.next()) |n| {
        count += countStones(n, 75, &cache);
    }

    return count;
}

test "part1 example" {
    const alloc = std.testing.allocator;

    const example = "125 17";

    var stream = std.io.fixedBufferStream(example);

    const result = try part1(alloc, stream.reader());

    try std.testing.expectEqual(55312, result);
}

test "part1 input" {
    const alloc = std.testing.allocator;

    const file_reader = try utils.FileReader.init(alloc, filename);
    defer file_reader.deinit();

    const result = try part1(alloc, file_reader.reader());

    try std.testing.expectEqual(193899, result);
}

test "part2 input" {
    const alloc = std.testing.allocator;

    const file_reader = try utils.FileReader.init(alloc, filename);
    defer file_reader.deinit();

    const result = try part2(alloc, file_reader.reader());

    try std.testing.expectEqual(229682160383225, result);
}
