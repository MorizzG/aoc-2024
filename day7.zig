const std = @import("std");

const utils = @import("lib/utils.zig");

const spice = @import("lib/spice.zig");

const day = "7";

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

fn checkEqnPlusMul(test_value: u64, cur_value: u64, eqn: []const u64) bool {
    if (eqn.len == 0) {
        return cur_value == test_value;
    }

    const x = eqn[0];

    // +
    {
        const next_value = cur_value + x;

        // if next_value > test_value: abort, can never get smaller
        if (next_value <= test_value) {
            if (checkEqnPlusMul(test_value, next_value, eqn[1..])) {
                return true;
            }
        }
    }

    // *
    {
        const next_value = cur_value * x;

        // if next_value > test_value: abort, can never get smaller
        if (next_value <= test_value) {
            if (checkEqnPlusMul(test_value, next_value, eqn[1..])) {
                return true;
            }
        }
    }

    return false;
}

fn checkEqnPlusMulPar(
    t: *spice.Task,
    args: struct {
        test_value: u64,
        cur_value: u64,
        eqn: []const u64,
    },
) bool {
    const test_value = args.test_value;
    const cur_value = args.cur_value;
    const eqn = args.eqn;

    if (cur_value > test_value) {
        return false;
    }

    if (eqn.len == 0) {
        return cur_value == test_value;
    }

    const x = eqn[0];

    var plus_fut = spice.Future(@TypeOf(args), bool).init();

    // +
    {
        const next_value = cur_value + x;

        // if next_value > test_value: abort, can never get smaller
        plus_fut.fork(t, checkEqnPlusMulPar, .{
            .test_value = test_value,
            .cur_value = next_value,
            .eqn = eqn[1..],
        });
    }

    // *
    {
        const next_value = cur_value * x;

        // if next_value > test_value: abort, can never get smaller
        if (next_value <= test_value) {
            if (t.call(bool, checkEqnPlusMulPar, .{ .test_value = test_value, .cur_value = next_value, .eqn = eqn[1..] })) {
                _ = plus_fut.join(t);
                return true;
            }
        }
    }

    if (plus_fut.join(t)) |b| {
        return b;
    } else {
        const next_value = cur_value + x;

        return t.call(bool, checkEqnPlusMulPar, .{ .test_value = test_value, .cur_value = next_value, .eqn = eqn[1..] });
    }
}

fn checkEqnPlusMulConcat(test_value: u64, cur_value: u64, eqn: []u64) bool {
    if (eqn.len == 0) {
        return cur_value == test_value;
    }

    const x = eqn[0];

    // +
    {
        const next_value = cur_value + x;

        // if next_value > test_value: abort, can never get smaller
        if (next_value <= test_value) {
            if (checkEqnPlusMulConcat(test_value, next_value, eqn[1..])) {
                return true;
            }
        }
    }

    if (cur_value == 0) {
        // for first value only plus is posible
        return false;
    }

    // *
    {
        const next_value = cur_value * x;

        // if next_value > test_value: abort, can never get smaller
        if (next_value <= test_value) {
            if (checkEqnPlusMulConcat(test_value, next_value, eqn[1..])) {
                return true;
            }
        }
    }

    // ||
    {
        const x_num_digits = utils.num_digits(x);

        const shift = std.math.powi(u64, 10, x_num_digits) catch unreachable;

        const new_value = shift * cur_value + x;

        // check with concatted value

        if (checkEqnPlusMulConcat(test_value, new_value, eqn[1..])) {
            return true;
        }
    }

    return false;
}

fn part1(alloc: std.mem.Allocator, reader: anytype) !u64 {
    var sum_calibration: u64 = 0;

    // var thread_pool = spice.ThreadPool.init(alloc);
    // defer thread_pool.deinit();

    // thread_pool.start(.{});

    var eqn = std.ArrayList(u64).init(alloc);
    defer eqn.deinit();

    var line_reader = utils.lineReader(alloc, reader);
    defer line_reader.deinit();

    while (try line_reader.next()) |line| {
        const colon_idx = std.mem.indexOfScalar(u8, line, ':') orelse unreachable;

        const test_value = try std.fmt.parseUnsigned(u64, line[0..colon_idx], 10);

        eqn.clearRetainingCapacity();

        var number_parser = utils.numberParser(u64, line[colon_idx + 1 ..]);

        while (try number_parser.next()) |n| {
            try eqn.append(n);
        }

        if (checkEqnPlusMul(test_value, 0, eqn.items)) {
            sum_calibration += test_value;
        }

        // if (thread_pool.call(bool, checkEqnPlusMulPar, .{
        //     .test_value = test_value,
        //     .cur_value = 0,
        //     .eqn = eqn.items,
        // })) {
        //     sum_calibration += test_value;
        // }
    }

    return sum_calibration;
}

fn part2(alloc: std.mem.Allocator, reader: anytype) !u64 {
    var sum_calibration: u64 = 0;

    // var thread_pool = spice.ThreadPool.init(alloc);
    // defer thread_pool.deinit();

    // thread_pool.start(.{});

    var eqn = std.ArrayList(u64).init(alloc);
    defer eqn.deinit();

    var line_reader = utils.lineReader(alloc, reader);
    defer line_reader.deinit();

    while (try line_reader.next()) |line| {
        const colon_idx = std.mem.indexOfScalar(u8, line, ':') orelse unreachable;

        const test_value = try std.fmt.parseUnsigned(u64, line[0..colon_idx], 10);

        eqn.clearRetainingCapacity();

        var number_parser = utils.numberParser(u64, line[colon_idx + 1 ..]);

        while (try number_parser.next()) |n| {
            try eqn.append(n);
        }

        if (checkEqnPlusMulConcat(test_value, 0, eqn.items)) {
            sum_calibration += test_value;
        }

        // if (thread_pool.call(bool, checkEqnPar, .{
        //     .test_value = test_value,
        //     .cur_value = 0,
        //     .eqn = eqn.items,
        // })) {
        //     sum_calibration += test_value;
        // }
    }

    return sum_calibration;
}

test "part1 example" {
    const alloc = std.testing.allocator;

    const example =
        \\190: 10 19
        \\3267: 81 40 27
        \\83: 17 5
        \\156: 15 6
        \\7290: 6 8 6 15
        \\161011: 16 10 13
        \\192: 17 8 14
        \\21037: 9 7 18 13
        \\292: 11 6 16 20
    ;

    var stream = std.io.fixedBufferStream(example);

    const result = try part1(alloc, stream.reader());

    try std.testing.expectEqual(3749, result);
}

test "part1 input" {
    const alloc = std.testing.allocator;

    const file_reader = try utils.FileReader.init(alloc, filename);
    defer file_reader.deinit();

    const result = try part1(alloc, file_reader.reader());

    try std.testing.expectEqual(1985268524462, result);
}

test "part2 example" {
    const alloc = std.testing.allocator;

    const example =
        \\190: 10 19
        \\3267: 81 40 27
        \\83: 17 5
        \\156: 15 6
        \\7290: 6 8 6 15
        \\161011: 16 10 13
        \\192: 17 8 14
        \\21037: 9 7 18 13
        \\292: 11 6 16 20
    ;

    var stream = std.io.fixedBufferStream(example);

    const result = try part2(alloc, stream.reader());

    try std.testing.expectEqual(11387, result);
}

test "part2 input" {
    const alloc = std.testing.allocator;

    const file_reader = try utils.FileReader.init(alloc, filename);
    defer file_reader.deinit();

    const result = try part2(alloc, file_reader.reader());

    try std.testing.expectEqual(150077710195188, result);
}
