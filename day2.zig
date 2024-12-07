const std = @import("std");

const utils = @import("lib/utils.zig");

const filename = "inputs/day2.txt";

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();

    {
        const file_reader = try utils.FileReader.init(alloc, filename);
        defer file_reader.deinit();

        const result = try part1(alloc, file_reader.reader());

        try std.io.getStdOut().writer().print("Day 2, part 1: {}\n", .{result});
    }

    {
        const file_reader = try utils.FileReader.init(alloc, filename);
        defer file_reader.deinit();

        const result = try part2(alloc, file_reader.reader());

        try std.io.getStdOut().writer().print("Day 2, part 2: {}\n", .{result});
    }
}

fn Chain(comptime T: type) type {
    return struct {
        slice1: []const T,
        slice2: []const T,

        fn len(self: *const @This()) usize {
            return self.slice1.len + self.slice2.len;
        }

        fn get(self: *const @This(), i: usize) T {
            var idx = i;

            if (idx < self.slice1.len) {
                return self.slice1[idx];
            }

            idx -= self.slice1.len;

            if (idx < self.slice2.len) {
                return self.slice2[idx];
            }

            unreachable;
        }
    };
}

fn check(report: []const i32) bool {
    var window = std.mem.window(i32, report, 2, 1);

    if (report[0] < report[1]) {
        while (window.next()) |x| {
            std.debug.assert(x.len == 2);

            const diff = x[1] - x[0];

            if (diff < 1 or diff > 3) {
                return false;
            }
        }
    } else if (report[0] > report[1]) {
        while (window.next()) |x| {
            std.debug.assert(x.len == 2);

            const diff = x[0] - x[1];

            if (diff < 1 or diff > 3) {
                return false;
            }
        }
    } else {
        return false;
    }

    return true;
}

fn check_with_skip(report: []const i32, skip_idx: usize) bool {
    const chain = Chain(i32){ .slice1 = report[0..skip_idx], .slice2 = report[skip_idx + 1 ..] };

    if (chain.get(0) < chain.get(1)) {
        for (0..(chain.len() - 1)) |i| {
            const diff = chain.get(i + 1) - chain.get(i);

            if (diff < 1 or diff > 3) {
                return false;
            }
        }
    } else if (chain.get(0) > chain.get(1)) {
        for (0..(chain.len() - 1)) |i| {
            const diff = chain.get(i) - chain.get(i + 1);

            if (diff < 1 or diff > 3) {
                return false;
            }
        }
    } else {
        return false;
    }

    return true;
}

fn part1(alloc: std.mem.Allocator, reader: anytype) !u32 {
    var line_reader = utils.lineReader(alloc, reader);
    defer line_reader.deinit();

    var report = std.ArrayList(i32).init(alloc);
    defer report.deinit();

    var num_safe_reports: u32 = 0;

    while (try line_reader.next()) |line| {
        report.clearRetainingCapacity();

        var number_parser = utils.numberParser(i32, line);

        while (try number_parser.next()) |n| {
            try report.append(n);
        }

        if (check(report.items)) {
            num_safe_reports += 1;
        }
    }

    return num_safe_reports;
}

fn part2(alloc: std.mem.Allocator, reader: anytype) !u32 {
    var line_reader = utils.lineReader(alloc, reader);
    defer line_reader.deinit();

    var report = std.ArrayList(i32).init(alloc);
    defer report.deinit();

    var num_safe_reports: u32 = 0;

    report_loop: while (try line_reader.next()) |line| {
        report.clearRetainingCapacity();

        // var it = std.mem.tokenizeScalar(u8, line, ' ');

        var number_parser = utils.numberParser(i32, line);

        while (try number_parser.next()) |n| {
            try report.append(n);
        }

        if (report.items.len < 2) {
            return error.ReportTooSmall;
        }

        if (check(report.items)) {
            num_safe_reports += 1;
        } else {
            for (0..report.items.len) |skip_idx| {
                if (check_with_skip(report.items, skip_idx)) {
                    num_safe_reports += 1;
                    continue :report_loop;
                }
            }
        }
    }

    return num_safe_reports;
}

test "part1 example" {
    const alloc = std.testing.allocator;

    const example =
        \\7 6 4 2 1
        \\1 2 7 8 9
        \\9 7 6 2 1
        \\1 3 2 4 5
        \\8 6 4 4 1
        \\1 3 6 7 9
    ;

    var stream = std.io.fixedBufferStream(example);

    const result = try part1(alloc, stream.reader());

    try std.testing.expectEqual(2, result);
}

test "part1 input" {
    const alloc = std.testing.allocator;

    const file_reader = try utils.FileReader.init(alloc, filename);
    defer file_reader.deinit();

    const result = try part1(alloc, file_reader.reader());

    try std.testing.expectEqual(549, result);
}

test "part2 example" {
    const alloc = std.testing.allocator;

    const example =
        \\7 6 4 2 1
        \\1 2 7 8 9
        \\9 7 6 2 1
        \\1 3 2 4 5
        \\8 6 4 4 1
        \\1 3 6 7 9
    ;

    var stream = std.io.fixedBufferStream(example);

    const result = try part2(alloc, stream.reader());

    try std.testing.expectEqual(4, result);
}

test "part2 input" {
    const alloc = std.testing.allocator;

    const file_reader = try utils.FileReader.init(alloc, filename);
    defer file_reader.deinit();

    const result = try part2(alloc, file_reader.reader());

    try std.testing.expectEqual(589, result);
}
