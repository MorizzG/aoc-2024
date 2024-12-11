const std = @import("std");

const utils = @import("lib/utils.zig");

const day = "6";

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

const Orientation = enum {
    up,
    right,
    down,
    left,
};

const MapElem = enum {
    empty,
    obstacle,
    guard,
    visited,
};

const GuardPos = struct {
    x: i32,
    y: i32,
    orientation: Orientation,
};

const Map = [][]MapElem;

const MapState = struct {
    alloc: std.mem.Allocator,

    size_x: usize,
    size_y: usize,

    map: Map,

    guard_pos: GuardPos,

    pub fn format(self: @This(), comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = fmt;
        _ = options;

        for (self.map) |line| {
            for (line) |elem| {
                const c: u8 = switch (elem) {
                    .empty => '.',
                    .guard => switch (self.guard_pos.orientation) {
                        .up => '^',
                        .down => 'v',
                        .left => '<',
                        .right => '>',
                    },
                    .obstacle => '#',
                    .visited => 'X',
                };

                try writer.print("{c}", .{c});
            }

            try writer.print("\n", .{});
        }
    }

    fn deinit(self: MapState) void {
        for (self.map) |map_line| {
            self.alloc.free(map_line);
        }

        self.alloc.free(self.map);
    }

    fn copyFrom(self: *MapState, other: MapState) void {
        for (self.map, other.map) |*map_line, map_line_orig| {
            @memcpy(map_line.*, map_line_orig);
        }
    }

    fn clone(self: MapState, alloc: std.mem.Allocator) !MapState {
        const map_orig = self.map;

        const map = try alloc.alloc([]MapElem, map_orig.len);

        for (map, map_orig) |*map_line, map_line_orig| {
            map_line.* = try alloc.alloc(MapElem, map_line_orig.len);
        }

        var new_map_state = MapState{
            .alloc = alloc,
            .size_x = self.size_x,
            .size_y = self.size_y,
            .guard_pos = self.guard_pos,
            .map = map,
        };

        new_map_state.copyFrom(self);

        return new_map_state;
    }

    fn parse(alloc: std.mem.Allocator, reader: anytype) !MapState {
        var line_reader = utils.lineReader(alloc, reader);
        defer line_reader.deinit();

        var map = std.ArrayList([]MapElem).init(alloc);

        var guard_pos: GuardPos = undefined;

        var x: usize = 0;
        while (try line_reader.next()) |line| : (x += 1) {
            const map_line = try alloc.alloc(MapElem, line.len);

            for (0.., line, map_line) |y, c, *map_elem| {
                map_elem.* = switch (c) {
                    '.' => .empty,
                    '#' => .obstacle,
                    '^' => blk: {
                        guard_pos = GuardPos{
                            .x = @intCast(x),
                            .y = @intCast(y),
                            .orientation = .up,
                        };

                        break :blk .guard;
                    },
                    else => unreachable,
                };
            }

            try map.append(map_line);
        }

        const map_slice = try map.toOwnedSlice();
        map.deinit();

        const size_x = map_slice.len;
        const size_y = map_slice[0].len;

        for (map_slice) |map_line| {
            std.debug.assert(map_line.len == size_y);
        }

        return .{
            .alloc = alloc,
            .size_x = size_x,
            .size_y = size_y,
            .map = map_slice,
            .guard_pos = guard_pos,
        };
    }

    fn get(self: MapState, x: i32, y: i32) MapElem {
        std.debug.assert(0 <= x and x < (self.size_x));
        std.debug.assert(0 <= y and y < (self.size_y));

        return self.map[@intCast(x)][@intCast(y)];
    }

    fn set(self: *MapState, x: i32, y: i32, elem: MapElem) void {
        std.debug.assert(0 <= x and x < (self.size_x));
        std.debug.assert(0 <= y and y < (self.size_y));

        self.map[@intCast(x)][@intCast(y)] = elem;
    }

    fn turn(self: *MapState) void {
        self.guard_pos.orientation = switch (self.guard_pos.orientation) {
            .up => .right,
            .right => .down,
            .down => .left,
            .left => .up,
        };
    }

    fn nextPos(self: MapState) ?struct { x: i32, y: i32 } {
        const guard_pos = self.guard_pos;

        const x = guard_pos.x;
        const y = guard_pos.y;

        var new_x: i32 = undefined;
        var new_y: i32 = undefined;

        switch (guard_pos.orientation) {
            .up => {
                new_x = x - 1;
                new_y = y;

                if (new_x < 0) {
                    return null;
                }
            },
            .right => {
                new_x = x;
                new_y = y + 1;

                if (new_y >= self.size_y) {
                    return null;
                }
            },
            .down => {
                new_x = x + 1;
                new_y = y;

                if (new_x >= self.size_x) {
                    return null;
                }
            },
            .left => {
                new_x = x;
                new_y = y - 1;

                if (new_y < 0) {
                    return null;
                }
            },
        }

        return .{ .x = new_x, .y = new_y };
    }

    fn advance(self: *MapState) enum { not_done, done } {
        const guard_pos = &self.guard_pos;

        const x = guard_pos.x;
        const y = guard_pos.y;

        if (self.get(x, y) != .guard) {
            std.debug.print("x: {}    y: {}\n", .{ x, y });
            std.debug.print("map on failure:\n{}\n", .{self});
        }

        std.debug.assert(self.get(x, y) == .guard);

        const new_pos = self.nextPos() orelse {
            // walked out of the map
            std.debug.assert(self.get(x, y) == .guard);

            self.set(x, y, .visited);

            return .done;
        };

        const new_x = new_pos.x;
        const new_y = new_pos.y;

        if (self.get(new_x, new_y) == .obstacle) {
            // found obstacle: turn and advance
            self.turn();
            return advance(self);
        }

        std.debug.assert(self.get(x, y) == .guard);
        self.set(x, y, .visited);

        guard_pos.x = new_x;
        guard_pos.y = new_y;

        self.set(new_x, new_y, .guard);

        return .not_done;
    }

    fn countVisited(self: MapState) u64 {
        var count: u64 = 0;

        for (self.map) |line| {
            for (line) |elem| {
                std.debug.assert(elem != .guard);

                if (elem == .visited) {
                    count += 1;
                }
            }
        }

        return count;
    }
};

fn part1(alloc: std.mem.Allocator, reader: anytype) !u64 {
    var map_arena = std.heap.ArenaAllocator.init(alloc);
    defer map_arena.deinit();

    var map_state = try MapState.parse(map_arena.allocator(), reader);

    while (map_state.advance() != .done) {}

    const visited_count = map_state.countVisited();

    return visited_count;
}

fn part2(alloc: std.mem.Allocator, reader: anytype) !u64 {
    var map_arena = std.heap.ArenaAllocator.init(alloc);
    defer map_arena.deinit();

    const map_state_orig = try MapState.parse(map_arena.allocator(), reader);

    var map_state_iter = try map_state_orig.clone(map_arena.allocator());

    var tmp_arena = std.heap.ArenaAllocator.init(alloc);
    defer tmp_arena.deinit();

    var num_loops: u64 = 0;

    var map_state_all_obstacles = try map_state_orig.clone(alloc);
    defer map_state_all_obstacles.deinit();

    var guard_pos_set = std.AutoHashMap(GuardPos, void).init(alloc);
    defer guard_pos_set.deinit();

    while (map_state_iter.advance() != .done) {

        // current guard pos after last step
        const cur_guard_pos = map_state_iter.guard_pos;

        const cur_x = cur_guard_pos.x;
        const cur_y = cur_guard_pos.y;

        if (cur_x == map_state_orig.guard_pos.x and cur_y == map_state_orig.guard_pos.y) {
            // don't put obstacle at initial position!
            continue;
        }

        if (map_state_all_obstacles.get(cur_x, cur_y) == .obstacle) {
            // we already tried this one
            continue;
        }

        // clone original map state
        var map_state_modified = try map_state_orig.clone(tmp_arena.allocator());

        // put a new obstacle at the current position of the guard
        // since obstacles only influence the path of the guard if she would step on,
        // conversely the only relevant positions for new obstacles are the tiles she actually
        // steps on
        map_state_modified.set(cur_x, cur_y, .obstacle);
        map_state_all_obstacles.set(cur_x, cur_y, .obstacle);

        guard_pos_set.clearRetainingCapacity();

        try guard_pos_set.put(map_state_modified.guard_pos, {});

        while (map_state_modified.advance() != .done) {
            // std.debug.print("modified map:\n{}\n", .{map_state_modified});

            const guard_pos = map_state_modified.guard_pos;

            if (guard_pos_set.contains(guard_pos)) {
                num_loops += 1;
                break;
            }

            try guard_pos_set.put(map_state_modified.guard_pos, {});
        }

        _ = tmp_arena.reset(.retain_capacity);
    }

    return num_loops;
}

test "part1 example" {
    const alloc = std.testing.allocator;

    const example =
        \\....#.....
        \\.........#
        \\..........
        \\..#.......
        \\.......#..
        \\..........
        \\.#..^.....
        \\........#.
        \\#.........
        \\......#...
    ;

    var stream = std.io.fixedBufferStream(example);

    const result = try part1(alloc, stream.reader());

    try std.testing.expectEqual(41, result);
}

test "part1 input" {
    const alloc = std.testing.allocator;

    const file_reader = try utils.FileReader.init(alloc, filename);
    defer file_reader.deinit();

    const result = try part1(alloc, file_reader.reader());

    try std.testing.expectEqual(4722, result);
}

test "part2 example" {
    const alloc = std.testing.allocator;

    const example =
        \\....#.....
        \\.........#
        \\..........
        \\..#.......
        \\.......#..
        \\..........
        \\.#..^.....
        \\........#.
        \\#.........
        \\......#...
    ;

    var stream = std.io.fixedBufferStream(example);

    const result = try part2(alloc, stream.reader());

    try std.testing.expectEqual(6, result);
}

test "part2 input" {
    const alloc = std.testing.allocator;

    const file_reader = try utils.FileReader.init(alloc, filename);
    defer file_reader.deinit();

    const result = try part2(alloc, file_reader.reader());

    try std.testing.expectEqual(1602, result);
}
