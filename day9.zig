const std = @import("std");

const utils = @import("lib/utils.zig");

const spice = @import("lib/spice.zig");

const day = "9";

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

fn part1(alloc: std.mem.Allocator, reader: anytype) !u64 {
    const FsEntry = enum(u32) {
        empty = std.math.maxInt(u32),
        _,
    };

    const input = try reader.readAllAlloc(alloc, std.math.maxInt(usize));
    defer alloc.free(input);

    var filesystem_list = std.ArrayList(FsEntry).init(alloc);
    defer filesystem_list.deinit();

    var next_id: u16 = 0;
    var is_gap = false;

    for (input) |byte| {
        if (byte == '\n') {
            break;
        }

        std.debug.assert('0' <= byte and byte <= '9');

        const len: usize = @as(usize, byte - '0');

        if (is_gap) {
            try filesystem_list.appendNTimes(.empty, len);
        } else {
            try filesystem_list.appendNTimes(@enumFromInt(next_id), len);

            next_id += 1;

            std.debug.assert(next_id != @intFromEnum(FsEntry.empty));
        }

        is_gap = !is_gap;
    }

    const filesystem = filesystem_list.items;

    // for (filesystem) |x| {
    //     switch (x) {
    //         .empty => std.debug.print(".", .{}),
    //         else => std.debug.print("{}", .{@intFromEnum(x)}),
    //     }
    // }
    // std.debug.print("\n", .{});

    var start_idx: usize = 0;
    var end_idx: usize = filesystem.len - 1;

    while (start_idx < end_idx) {

        // for start_idx: seek next empty position
        if (filesystem[start_idx] != .empty) {
            start_idx += 1;
            continue;
        }

        // for end_idx: seek next full position
        if (filesystem[end_idx] == .empty) {
            end_idx -= 1;
            continue;
        }

        std.debug.assert(filesystem[start_idx] == .empty and filesystem[end_idx] != .empty);

        filesystem[start_idx] = filesystem[end_idx];
        filesystem[end_idx] = .empty;
    }

    const first_empty_idx = std.mem.indexOfScalar(FsEntry, filesystem, .empty).?;

    for (filesystem[first_empty_idx..]) |id| {
        std.debug.assert(id == .empty);
    }

    var checksum: u64 = 0;

    for (0.., filesystem) |idx, id| {
        if (id == .empty) {
            break;
        }

        checksum += @as(u64, idx) * @intFromEnum(id);
    }

    return checksum;
}

fn part2(alloc: std.mem.Allocator, reader: anytype) !u64 {
    const FsId = enum(u16) {
        empty = std.math.maxInt(u16),
        _,
    };

    const FsEntry = struct {
        len: u16,
        id: FsId,
    };

    const input = try reader.readAllAlloc(alloc, std.math.maxInt(usize));
    defer alloc.free(input);

    var filesystem = std.ArrayList(FsEntry).init(alloc);
    defer filesystem.deinit();

    var max_id: u16 = undefined;

    {
        var next_id: u16 = 0;
        var is_gap = false;

        for (input) |byte| {
            if (byte == '\n') {
                break;
            }

            std.debug.assert('0' <= byte and byte <= '9');

            const len: u16 = @as(u16, byte - '0');

            if (is_gap) {
                try filesystem.append(.{ .len = len, .id = .empty });
            } else {
                try filesystem.append(.{ .len = len, .id = @enumFromInt(next_id) });

                next_id += 1;

                std.debug.assert(next_id != @intFromEnum(FsId.empty));
            }

            is_gap = !is_gap;
        }

        max_id = next_id - 1;
    }

    // for (filesystem.items) |entry| {
    //     for (0..entry.len) |_| {
    //         switch (entry.id) {
    //             .empty => std.debug.print(".", .{}),
    //             else => std.debug.print("{}", .{@intFromEnum(entry.id)}),
    //         }
    //     }
    // }
    // std.debug.print("\n", .{});

    {
        // next ID to check; neccessary for checking all files once
        // since file entries are sorted in increasing order, we can simply decrease this with each
        // checked file
        var next_id = max_id;

        // index of next filesystem entry to check
        var idx: usize = filesystem.items.len - 1;
        while (idx > 0) : (idx -= 1) {
            const entry = filesystem.items[idx];

            // we should never see and ID smaller than the one we're looking for
            // if we do that means we would skip that file
            std.debug.assert(entry.id == .empty or @intFromEnum(entry.id) >= next_id);

            if (@intFromEnum(entry.id) != next_id) {
                continue;
            }

            // found next entry to move

            // decrease next ID to find
            next_id -= 1;

            const len = entry.len;

            for (0..idx) |jdx| {
                const target_entry = filesystem.items[jdx];

                // find the first entry with is empty and at least as large as our entry
                if (target_entry.id != .empty or target_entry.len < len) {
                    continue;
                }

                // found target entry

                if (target_entry.len == entry.len) {
                    // exact hit! no need to split entry, just swap IDs

                    std.mem.swap(FsId, &filesystem.items[idx].id, &filesystem.items[jdx].id);
                } else {
                    // empty space is larger than our entry; need to split

                    // warning! this (potentially) invalidates all pointers into filesystem.items
                    // and we need to adjust indices (i.e. increase idx by one) since everything after
                    // jdx shift back by one index

                    _ = try filesystem.addManyAt(jdx + 1, 1);

                    idx += 1;

                    // jdx + 1 becomes empty entry of len target_entry.len - entry.len
                    filesystem.items[jdx + 1].id = .empty;
                    filesystem.items[jdx + 1].len = target_entry.len - entry.len;

                    // jdx becomes entry
                    filesystem.items[jdx].len = entry.len;
                    filesystem.items[jdx].id = entry.id;

                    // idx becomes empty
                    filesystem.items[idx].id = .empty;
                }

                break;
            }
        }
    }

    // for (filesystem.items) |entry| {
    //     for (0..entry.len) |_| {
    //         switch (entry.id) {
    //             .empty => std.debug.print(".", .{}),
    //             else => std.debug.print("{}", .{@intFromEnum(entry.id)}),
    //         }
    //     }
    // }
    // std.debug.print("\n", .{});

    var checksum: u64 = 0;

    {
        var idx: usize = 0;

        for (filesystem.items) |entry| {
            const len = entry.len;

            // skip over empty entry
            if (entry.id == .empty) {
                idx += len;

                continue;
            }

            const id = @intFromEnum(entry.id);

            for (0..len) |_| {
                checksum += id * idx;

                idx += 1;
            }
        }
    }

    return checksum;
}

test "part1 example" {
    const alloc = std.testing.allocator;

    const example = "2333133121414131402";

    var stream = std.io.fixedBufferStream(example);

    const result = try part1(alloc, stream.reader());

    try std.testing.expectEqual(1928, result);
}

test "part1 input" {
    const alloc = std.testing.allocator;

    const file_reader = try utils.FileReader.init(alloc, filename);
    defer file_reader.deinit();

    const result = try part1(alloc, file_reader.reader());

    try std.testing.expectEqual(6307275788409, result);
}

test "part2 example" {
    const alloc = std.testing.allocator;

    const example = "2333133121414131402";

    var stream = std.io.fixedBufferStream(example);

    const result = try part2(alloc, stream.reader());

    try std.testing.expectEqual(2858, result);
}

test "part2 input" {
    const alloc = std.testing.allocator;

    const file_reader = try utils.FileReader.init(alloc, filename);
    defer file_reader.deinit();

    const result = try part2(alloc, file_reader.reader());

    try std.testing.expectEqual(6327174563252, result);
}
