const std = @import("std");

const utils = @import("lib/utils.zig");

const spice = @import("lib/spice.zig");

const day = "10";

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

const Pos = struct {
    x: i32,
    y: i32,
};

const Map = struct {
    size_x: u32,
    size_y: u32,

    map: []const []const u8,

    pub fn format(self: Map, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = fmt;
        _ = options;

        for (self.map) |line| {
            for (line) |x| {
                try writer.print("{} ", .{x});
            }

            _ = try writer.write("\n");
        }
    }

    fn get(self: Map, x: i32, y: i32) ?u8 {
        if (x < 0 or x >= @as(i32, @intCast(self.size_x)) or y < 0 or y >= @as(i32, @intCast(self.size_y))) {
            return null;
        }

        return self.map[@intCast(x)][@intCast(y)];
    }
};

fn findAllEnds(ends: *std.AutoHashMap(Pos, void), map: Map, start_pos: Pos) !void {
    const findAllEndsRec = struct {
        fn findAllEndsRec(_ends: *std.AutoHashMap(Pos, void), _map: Map, cur_pos: Pos, height: u8) !void {
            const cur_x = cur_pos.x;
            const cur_y = cur_pos.y;

            std.debug.assert(_map.get(cur_x, cur_y).? == height);

            if (height == 9) {
                try _ends.put(cur_pos, {});

                return;
            }

            {
                const new_x = cur_x - 1;
                const new_y = cur_y;

                if (_map.get(new_x, new_y)) |new_height| {
                    if (new_height == height + 1) {
                        try findAllEndsRec(_ends, _map, .{ .x = new_x, .y = new_y }, new_height);
                    }
                }
            }

            {
                const new_x = cur_x + 1;
                const new_y = cur_y;

                if (_map.get(new_x, new_y)) |new_height| {
                    if (new_height == height + 1) {
                        try findAllEndsRec(_ends, _map, .{ .x = new_x, .y = new_y }, new_height);
                    }
                }
            }

            {
                const new_x = cur_x;
                const new_y = cur_y - 1;

                if (_map.get(new_x, new_y)) |new_height| {
                    if (new_height == height + 1) {
                        try findAllEndsRec(_ends, _map, .{ .x = new_x, .y = new_y }, new_height);
                    }
                }
            }

            {
                const new_x = cur_x;
                const new_y = cur_y + 1;

                if (_map.get(new_x, new_y)) |new_height| {
                    if (new_height == height + 1) {
                        try findAllEndsRec(_ends, _map, .{ .x = new_x, .y = new_y }, new_height);
                    }
                }
            }
        }
    }.findAllEndsRec;

    try findAllEndsRec(ends, map, start_pos, 0);
}

fn countAllTrails(map: Map, start_pos: Pos) !u64 {
    const countAllTrailsRec = struct {
        fn countAllTrailsRec(_map: Map, cur_pos: Pos, height: u8) !u64 {
            const cur_x = cur_pos.x;
            const cur_y = cur_pos.y;

            std.debug.assert(_map.get(cur_x, cur_y).? == height);

            if (height == 9) {
                return 1;
            }

            var count: u64 = 0;

            {
                const new_x = cur_x - 1;
                const new_y = cur_y;

                if (_map.get(new_x, new_y)) |new_height| {
                    if (new_height == height + 1) {
                        count += try countAllTrailsRec(_map, .{ .x = new_x, .y = new_y }, new_height);
                    }
                }
            }

            {
                const new_x = cur_x + 1;
                const new_y = cur_y;

                if (_map.get(new_x, new_y)) |new_height| {
                    if (new_height == height + 1) {
                        count += try countAllTrailsRec(_map, .{ .x = new_x, .y = new_y }, new_height);
                    }
                }
            }

            {
                const new_x = cur_x;
                const new_y = cur_y - 1;

                if (_map.get(new_x, new_y)) |new_height| {
                    if (new_height == height + 1) {
                        count += try countAllTrailsRec(_map, .{ .x = new_x, .y = new_y }, new_height);
                    }
                }
            }

            {
                const new_x = cur_x;
                const new_y = cur_y + 1;

                if (_map.get(new_x, new_y)) |new_height| {
                    if (new_height == height + 1) {
                        count += try countAllTrailsRec(_map, .{ .x = new_x, .y = new_y }, new_height);
                    }
                }
            }

            return count;
        }
    }.countAllTrailsRec;

    return try countAllTrailsRec(map, start_pos, 0);
}

fn part1(alloc: std.mem.Allocator, reader: anytype) !u64 {
    var map_arena = std.heap.ArenaAllocator.init(alloc);
    defer map_arena.deinit();

    var map_list = std.ArrayList([]const u8).init(map_arena.allocator());
    defer map_list.deinit();

    var line_reader = utils.lineReader(alloc, reader);
    defer line_reader.deinit();

    while (try line_reader.next()) |line| {
        const map_line = try map_arena.allocator().alloc(u8, line.len);

        for (line, map_line) |c, *x| {
            std.debug.assert('0' <= c and c <= '9');

            x.* = c - '0';
        }

        try map_list.append(map_line);
    }

    const size_x = map_list.items.len;
    const size_y = map_list.items[0].len;

    for (map_list.items) |line| {
        std.debug.assert(line.len == size_y);
    }

    const map = Map{ .size_x = @intCast(size_x), .size_y = @intCast(size_y), .map = map_list.items };

    var count: u64 = 0;

    var ends = std.AutoHashMap(Pos, void).init(alloc);
    defer ends.deinit();

    for (0..size_x) |x| {
        for (0..size_y) |y| {
            if (map.get(@intCast(x), @intCast(y)) != 0) {
                continue;
            }

            ends.clearRetainingCapacity();

            try findAllEnds(&ends, map, .{ .x = @intCast(x), .y = @intCast(y) });

            count += @intCast(ends.count());
        }
    }

    return count;
}

fn part2(alloc: std.mem.Allocator, reader: anytype) !u64 {
    var map_arena = std.heap.ArenaAllocator.init(alloc);
    defer map_arena.deinit();

    var map_list = std.ArrayList([]const u8).init(map_arena.allocator());
    defer map_list.deinit();

    var line_reader = utils.lineReader(alloc, reader);
    defer line_reader.deinit();

    while (try line_reader.next()) |line| {
        const map_line = try map_arena.allocator().alloc(u8, line.len);

        for (line, map_line) |c, *x| {
            std.debug.assert('0' <= c and c <= '9');

            x.* = c - '0';
        }

        try map_list.append(map_line);
    }

    const size_x = map_list.items.len;
    const size_y = map_list.items[0].len;

    for (map_list.items) |line| {
        std.debug.assert(line.len == size_y);
    }

    const map = Map{ .size_x = @intCast(size_x), .size_y = @intCast(size_y), .map = map_list.items };

    var count: u64 = 0;

    var ends = std.AutoHashMap(Pos, void).init(alloc);
    defer ends.deinit();

    for (0..size_x) |x| {
        for (0..size_y) |y| {
            if (map.get(@intCast(x), @intCast(y)) != 0) {
                continue;
            }

            ends.clearRetainingCapacity();

            const num_trails = try countAllTrails(map, .{ .x = @intCast(x), .y = @intCast(y) });

            count += num_trails;
        }
    }

    return count;
}

test "part1 example" {
    const alloc = std.testing.allocator;

    const example =
        \\89010123
        \\78121874
        \\87430965
        \\96549874
        \\45678903
        \\32019012
        \\01329801
        \\10456732
    ;

    var stream = std.io.fixedBufferStream(example);

    const result = try part1(alloc, stream.reader());

    try std.testing.expectEqual(36, result);
}

test "part1 input" {
    const alloc = std.testing.allocator;

    const file_reader = try utils.FileReader.init(alloc, filename);
    defer file_reader.deinit();

    const result = try part1(alloc, file_reader.reader());

    try std.testing.expectEqual(629, result);
}

test "part2 example" {
    const alloc = std.testing.allocator;

    const example =
        \\89010123
        \\78121874
        \\87430965
        \\96549874
        \\45678903
        \\32019012
        \\01329801
        \\10456732
    ;

    var stream = std.io.fixedBufferStream(example);

    const result = try part2(alloc, stream.reader());

    try std.testing.expectEqual(81, result);
}

test "part2 input" {
    const alloc = std.testing.allocator;

    const file_reader = try utils.FileReader.init(alloc, filename);
    defer file_reader.deinit();

    const result = try part2(alloc, file_reader.reader());

    try std.testing.expectEqual(1242, result);
}
