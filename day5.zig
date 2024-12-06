const std = @import("std");

const utils = @import("utils.zig");

const List = std.DoublyLinkedList(u8);

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();

    const filename = "inputs/day5.txt";

    {
        const file_reader = try utils.FileReader.init(alloc, filename);
        defer file_reader.deinit();

        const result = try part1(alloc, file_reader.reader());

        try std.io.getStdOut().writer().print("Day 5, part 1: {}\n", .{result});
    }

    {
        const file_reader = try utils.FileReader.init(alloc, filename);
        defer file_reader.deinit();

        const result = try part2(alloc, file_reader.reader());

        try std.io.getStdOut().writer().print("Day 5, part 2: {}\n", .{result});
    }
}

const Edge = struct { from: u8, to: u8 };

fn isCorrectlyOrdered(pages: []const u8, edges: std.AutoHashMap(Edge, void)) bool {
    for (0..pages.len) |i| {
        for (i + 1..pages.len) |j| {
            const edge = Edge{ .from = pages[j], .to = pages[i] };

            if (edges.contains(edge)) {
                return false;
            }
        }
    }

    return true;
}

fn findIndex(slice: []const u8, value: u8) ?usize {
    for (0.., slice) |i, x| {
        if (x == value) {
            return i;
        }
    }

    return null;
}

fn findNode(list: List, value: u8) ?*List.Node {
    var node_ptr_maybe = list.first;

    while (node_ptr_maybe != null) : (node_ptr_maybe = node_ptr_maybe.?.next) {
        const node_ptr = node_ptr_maybe.?;

        if (node_ptr.*.data == value) {
            return node_ptr;
        }
    }

    return null;
}

fn topo_sort(elems: []u8, incoming_edges: std.AutoHashMap(u8, List), outgoing_edges: std.AutoHashMap(u8, List)) void {
    // this function works in-place by splitting elems into an first, sorted part and a later,
    // unsorted part

    var _incoming_edges = incoming_edges;
    var _outgoing_edges = outgoing_edges;

    // this index marks the first element of the unsorted part of elems
    var next_unsorted_idx: usize = 0;

    // step 1: find all nodes with no incoming edges, move them to the sorted part of the list
    for (next_unsorted_idx..elems.len) |i| {
        if (_incoming_edges.get(elems[i]) == null) {
            // if elems[i] has no incoming edges, move it to the end of the sorted list
            std.mem.swap(u8, &elems[next_unsorted_idx], &elems[i]);

            // advance end of sorted list by one
            next_unsorted_idx += 1;
        }
    }

    // step 2: progressively iterate over sorted section, removing outgoing edges and adding nodes
    // with no incoming edges to the end of the sorted section
    for (elems) |value| {
        // if value has outgoing edges...
        if (_outgoing_edges.get(value)) |outgoing_list| {
            // iterate over outgoing edges
            var node_ptr_maybe = outgoing_list.first;
            while (node_ptr_maybe != null) : (node_ptr_maybe = node_ptr_maybe.?.next) {
                const node_ptr = node_ptr_maybe.?;

                const to_value = node_ptr.*.data;

                if (_incoming_edges.getPtr(to_value)) |incoming_list_ptr| {
                    // cannot fail: we know the edge (value, to_value) existts
                    const node = findNode(incoming_list_ptr.*, value).?;

                    // remove edge
                    incoming_list_ptr.remove(node);

                    if (incoming_list_ptr.len == 0) {
                        _ = _incoming_edges.remove(to_value);

                        // cannot fail: to_elem must be in unsorted section of elems // [next_unsorted_idx..]
                        const to_value_index = next_unsorted_idx + findIndex(elems[next_unsorted_idx..], to_value).?;

                        // std.debug.print("{}    {}\n\n", .{ next_unsorted_idx, to_value_index });

                        std.mem.swap(u8, &elems[next_unsorted_idx], &elems[to_value_index]);
                        next_unsorted_idx += 1;
                    }
                } else {
                    // we know we have an edge (value, to_value), can't fail
                    unreachable;
                }
            }

            // remove all outgoing edges at once
            _ = _outgoing_edges.remove(value);
        }
    }

    std.debug.assert(_incoming_edges.count() == 0);
    std.debug.assert(_outgoing_edges.count() == 0);
}

fn part1(alloc: std.mem.Allocator, reader: anytype) !u64 {
    var line_reader = utils.lineReader(alloc, reader);
    defer line_reader.deinit();

    // var elems_set = std.AutoHashMap(u8, void).init(alloc);
    // defer elems_set.deinit();

    // var edge_arena = std.heap.ArenaAllocator.init(alloc);
    // defer edge_arena.deinit();

    var edges = std.AutoHashMap(Edge, void).init(alloc);
    defer edges.deinit();

    // var outgoing_edges = std.AutoHashMap(u8, List).init(edge_arena.allocator());
    // var incoming_edges = std.AutoHashMap(u8, List).init(edge_arena.allocator());

    while (try line_reader.next()) |line| {
        if (line.len == 0) {
            break;
        }

        var it = utils.numberParserWithDelimiter(u8, line, '|');

        const from = (try it.next()).?;
        const to = (try it.next()).?;

        std.debug.assert((try it.next()) == null);

        // try elems_set.put(from, {});
        // try elems_set.put(to, {});

        // try edges.append(.{ .from = from, .to = to });
        try edges.put(.{ .from = from, .to = to }, {});

        // _ = try outgoing_edges.getOrPutValue(from, List{});

        // if (outgoing_edges.getPtr(from)) |list| {
        //     const node_ptr = try edge_arena.allocator().create(List.Node);
        //     node_ptr.*.data = to;

        //     list.*.prepend(node_ptr);
        // } else {
        //     unreachable;
        // }

        // _ = try incoming_edges.getOrPutValue(to, List{});

        // if (incoming_edges.getPtr(to)) |list| {
        //     const node_ptr = try edge_arena.allocator().create(List.Node);
        //     node_ptr.*.data = from;

        //     list.*.prepend(node_ptr);
        // } else {
        //     unreachable;
        // }
    }

    // const elems = blk: {
    //     const elems = try alloc.alloc(u8, elems_set.count());

    //     var it = elems_set.iterator();

    //     for (elems) |*p| {
    //         p.* = it.next().?.key_ptr.*;
    //     }

    //     std.debug.assert(it.next() == null);

    //     break :blk elems;
    // };
    // defer alloc.free(elems);

    // topo_sort(elems, incoming_edges, outgoing_edges);

    // std.debug.print("sorted elems:  ", .{});
    // utils.printSlice(u8, elems);
    // std.debug.print("\n", .{});

    // for (edges.items) |edge| {
    //     std.debug.print("from: {}    to: {}\n", .{ edge.from, edge.to });

    //     const from_idx = findIndex(elems, edge.from).?;
    //     const to_idx = findIndex(elems, edge.to).?;

    //     std.debug.print("from_idx: {}    to_idx: {}\n", .{ from_idx, to_idx });

    //     std.debug.assert(from_idx < to_idx);
    // }

    var update = std.ArrayList(u8).init(alloc);
    defer update.deinit();

    var sum_middle_pages: u64 = 0;

    while (try line_reader.next()) |line| {
        update.clearRetainingCapacity();

        var it = utils.numberParserWithDelimiter(u8, line, ',');

        while (try it.next()) |n| {
            try update.append(n);
        }

        std.debug.assert(update.items.len % 2 == 1);

        // var update_idx: usize = 0;

        // for (elems) |n| {
        //     if (update.items[update_idx] == n) {
        //         update_idx += 1;
        //     }

        //     if (update_idx == update.items.len) {
        //         const middle_idx = update.items.len / 2;

        //         sum_middle_pages += update.items[middle_idx];

        //         break;
        //     }
        // }

        if (isCorrectlyOrdered(update.items, edges)) {
            const middle_idx = update.items.len / 2;

            sum_middle_pages += update.items[middle_idx];
        }
    }

    return sum_middle_pages;
}

fn part2(alloc: std.mem.Allocator, reader: anytype) !u32 {
    _ = alloc;
    _ = reader;

    return 0;
}

test "part1 example" {
    const alloc = std.testing.allocator;

    const example =
        \\47|53
        \\97|13
        \\97|61
        \\97|47
        \\75|29
        \\61|13
        \\75|53
        \\29|13
        \\97|29
        \\53|29
        \\61|53
        \\97|53
        \\61|29
        \\47|13
        \\75|47
        \\97|75
        \\47|61
        \\75|61
        \\47|29
        \\75|13
        \\53|13
        \\
        \\75,47,61,53,29
        \\97,61,53,29,13
        \\75,29,13
        \\75,97,47,61,53
        \\61,13,29
        \\97,13,75,29,47
    ;

    var stream = std.io.fixedBufferStream(example);

    const result = try part1(alloc, stream.reader());

    try std.testing.expect(result == 143);
}

test "part1 input" {
    const alloc = std.testing.allocator;

    const filename = "inputs/day5.txt";

    const file_reader = try utils.FileReader.init(alloc, filename);
    defer file_reader.deinit();

    const result = try part1(alloc, file_reader.reader());

    try std.testing.expect(result == 5129);
}

// test "part2 example" {
//     const alloc = std.testing.allocator;

//     const example =
//         \\MMMSXXMASM
//         \\MSAMXMSMSA
//         \\AMXSXMAAMM
//         \\MSAMASMSMX
//         \\XMASAMXAMM
//         \\XXAMMXXAMA
//         \\SMSMSASXSS
//         \\SAXAMASAAA
//         \\MAMMMXMMMM
//         \\MXMXAXMASX
//     ;

//     var stream = std.io.fixedBufferStream(example);

//     const result = try part2(alloc, stream.reader());

//     try std.testing.expect(result == 9);
// }

// test "part2 input" {
//     const alloc = std.testing.allocator;

//     const filename = "inputs/day5.txt";

//     const file_reader = try utils.FileReader.init(alloc, filename);
//     defer file_reader.deinit();

//     const result = try part2(alloc, file_reader.reader());

//     try std.testing.expect(result == 1950);
// }
