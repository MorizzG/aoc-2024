const std = @import("std");

const utils = @import("lib/utils.zig");

const isDigit = std.ascii.isDigit;

const filename = "inputs/day3.txt";

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();

    {
        const file_reader = try utils.FileReader.init(alloc, filename);
        defer file_reader.deinit();

        const result = try part1(alloc, file_reader.reader());

        try std.io.getStdOut().writer().print("Day 3, part 1: {}\n", .{result});
    }

    {
        const file_reader = try utils.FileReader.init(alloc, filename);
        defer file_reader.deinit();

        const result = try part2(alloc, file_reader.reader());

        try std.io.getStdOut().writer().print("Day 3, part 2: {}\n", .{result});
    }
}

fn part1(alloc: std.mem.Allocator, reader: anytype) !u64 {
    const input = try reader.readAllAlloc(alloc, std.math.maxInt(u64));
    defer alloc.free(input);

    const mul_prefix = "mul(";

    std.debug.assert(mul_prefix.len == 4);

    var total: u64 = 0;

    var idx: usize = 0;
    var i: usize = 0;

    outer: while (idx < input.len) : (idx += @max(i, 1)) {
        const rest = input[idx..];

        i = 0;

        while (i < mul_prefix.len) : (i += 1) {
            if (rest[i] != mul_prefix[i]) {
                continue :outer;
            }
        }

        // parse first number

        var start: usize = i;

        // next char must be a digit
        if (isDigit(rest[i])) {
            i += 1;
        } else {
            continue;
        }

        // consume up to 2 more digits
        for (0..2) |_| {
            if (isDigit(rest[i])) {
                i += 1;
            }
        }

        // already validated we're parsing a valid number
        const left = std.fmt.parseUnsigned(u32, rest[start..i], 10) catch unreachable;

        if (rest[i] != ',') {
            continue;
        }

        // consume ','
        i += 1;

        // parse second number

        start = i;

        // next char must be a digit
        if (isDigit(rest[i])) {
            i += 1;
        } else {
            continue;
        }

        // consume up to 2 more digits
        for (0..2) |_| {
            if (isDigit(rest[i])) {
                i += 1;
            }
        }

        // already validated we're parsing a valid number
        const right = std.fmt.parseUnsigned(u32, rest[start..i], 10) catch unreachable;

        if (rest[i] != ')') {
            continue;
        }

        // consume ')'
        i += 1;

        total += left * right;
    }

    return total;
}

fn part2(alloc: std.mem.Allocator, reader: anytype) !u64 {
    const input = try reader.readAllAlloc(alloc, std.math.maxInt(u64));
    defer alloc.free(input);

    // std.debug.print("{s}\n", .{input});

    // var tok_it = std.mem.tokenizeSequence(u8, input, "mul(");

    const mul_prefix = "mul(";
    const do = "do()";
    const dont = "don't()";

    var total: u64 = 0;

    var idx: usize = 0;
    var i: usize = 0;

    var enabled = true;

    outer: while (idx < input.len) : (idx += @max(i, 1)) {
        const rest = input[idx..];

        i = 0;

        if (!enabled) {
            while (i < do.len) : (i += 1) {
                if (rest[i] != do[i]) {
                    continue :outer;
                }
            }

            enabled = true;
            continue;
        }

        if (rest[i] == 'd') {
            i += 1;

            while (i < do.len) : (i += 1) {
                if (rest[i] != dont[i]) {
                    continue :outer;
                }
            }

            enabled = false;
            continue;
        }

        while (i < mul_prefix.len) : (i += 1) {
            if (rest[i] != mul_prefix[i]) {
                continue :outer;
            }
        }

        // parse first number

        var start: usize = i;

        // next char must be a digit
        if (isDigit(rest[i])) {
            i += 1;
        } else {
            continue;
        }

        // consume up to 2 more digits
        for (0..2) |_| {
            if (isDigit(rest[i])) {
                i += 1;
            }
        }

        // already validated we're parsing a valid number
        const left = std.fmt.parseUnsigned(u32, rest[start..i], 10) catch unreachable;

        if (rest[i] != ',') {
            continue;
        }

        // consume ','
        i += 1;

        // parse second number

        start = i;

        // next char must be a digit
        if (isDigit(rest[i])) {
            i += 1;
        } else {
            continue;
        }

        // consume up to 2 more digits
        for (0..2) |_| {
            if (isDigit(rest[i])) {
                i += 1;
            }
        }

        // already validated we're parsing a valid number
        const right = std.fmt.parseUnsigned(u32, rest[start..i], 10) catch unreachable;

        if (rest[i] != ')') {
            continue;
        }

        // consume ')'
        i += 1;

        total += left * right;
    }

    return total;
}

test "part1 example" {
    const alloc = std.testing.allocator;

    const example = "xmul(2,4)%&mul[3,7]!@^do_not_mul(5,5)+mul(32,64]then(mul(11,8)mul(8,5))";

    var stream = std.io.fixedBufferStream(example);

    const result = try part1(alloc, stream.reader());

    try std.testing.expectEqual(161, result);
}

test "part1 input" {
    const alloc = std.testing.allocator;

    const file_reader = try utils.FileReader.init(alloc, filename);
    defer file_reader.deinit();

    const result = try part1(alloc, file_reader.reader());

    try std.testing.expectEqual(156388521, result);
}

test "part2 example" {
    const alloc = std.testing.allocator;

    const example = "xmul(2,4)&mul[3,7]!^don't()_mul(5,5)+mul(32,64](mul(11,8)undo()?mul(8,5))";

    var stream = std.io.fixedBufferStream(example);

    const result = try part2(alloc, stream.reader());

    try std.testing.expectEqual(48, result);
}

test "part2 input" {
    const alloc = std.testing.allocator;

    const file_reader = try utils.FileReader.init(alloc, filename);
    defer file_reader.deinit();

    const result = try part2(alloc, file_reader.reader());

    try std.testing.expectEqual(75920122, result);
}
