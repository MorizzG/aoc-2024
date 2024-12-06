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

fn checkUndefined(comptime T: type, ptr: *const T) bool {
    const bytes = std.mem.asBytes(ptr);

    for (bytes) |byte| {
        if (byte != 0xaa) {
            return false;
        }
    }

    return true;
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

fn topo_sort(alloc: std.mem.Allocator, elems: []u8, edges: std.AutoHashMap(Edge, void)) !void {

    // first build maps of edges

    var outgoing_edges = std.AutoHashMap(u8, std.AutoHashMap(u8, void)).init(alloc);
    var incoming_edges = std.AutoHashMap(u8, std.AutoHashMap(u8, void)).init(alloc);

    {
        var it = edges.iterator();

        while (it.next()) |edge| {
            const from = edge.key_ptr.from;
            const to = edge.key_ptr.to;

            // if either to or from are not in elems, ignore this edge
            // -> not in subgraph spanned by elems
            if (findIndex(elems, from) == null or findIndex(elems, to) == null) {
                continue;
            }

            // add outgoing edge to outgoing_edges[from][to]

            const outgoing_entry = try outgoing_edges.getOrPut(from);

            if (!outgoing_entry.found_existing) {
                // check for undefined
                std.debug.assert(checkUndefined(@TypeOf(outgoing_entry.value_ptr.*), outgoing_entry.value_ptr));

                outgoing_entry.value_ptr.* = std.AutoHashMap(u8, void).init(alloc);
            }

            // check for undefined
            std.debug.assert(!checkUndefined(@TypeOf(outgoing_entry.value_ptr.*), outgoing_entry.value_ptr));

            try outgoing_entry.value_ptr.put(to, {});

            // add incoming edge to incoming_edges[to][from]

            const incoming_entry = try incoming_edges.getOrPut(to);

            if (!incoming_entry.found_existing) {
                std.debug.assert(checkUndefined(@TypeOf(incoming_entry.value_ptr.*), incoming_entry.value_ptr));

                incoming_entry.value_ptr.* = std.AutoHashMap(u8, void).init(alloc);
            }

            std.debug.assert(!checkUndefined(@TypeOf(incoming_entry.value_ptr.*), incoming_entry.value_ptr));

            try incoming_entry.value_ptr.put(from, {});
        }
    }

    {
        var it = edges.iterator();

        while (it.next()) |edge| {
            const from = edge.key_ptr.from;
            const to = edge.key_ptr.to;

            // if either to or from are not in elems, ignore this edge
            // -> not in subgraph spanned by elems
            if (findIndex(elems, from) == null or findIndex(elems, to) == null) {
                continue;
            }

            std.debug.assert(outgoing_edges.get(from).?.get(to) != null);
            std.debug.assert(incoming_edges.get(to).?.get(from) != null);
        }
    }

    // this function works in-place by splitting elems into an first, sorted part and a later,
    // unsorted part

    // this index marks the first element of the unsorted part of elems
    var next_unsorted_idx: usize = 0;

    // step 1: find all nodes with no incoming edges, move them to the sorted part of the list
    for (0..elems.len) |i| {
        const incoming_set = incoming_edges.get(elems[i]);

        if (incoming_set == null) {
            // if elems[i] has no incoming edges, move it to the end of the sorted list
            std.mem.swap(u8, &elems[next_unsorted_idx], &elems[i]);

            // advance end of sorted list by one
            next_unsorted_idx += 1;
        } else {
            std.debug.assert(incoming_set.?.count() != 0);
        }
    }

    // step 2: progressively iterate over sorted section, removing outgoing edges and adding nodes
    // with no incoming edges to the end of the sorted section
    for (elems) |value| {

        // if value has outgoing edges...
        if (outgoing_edges.get(value)) |outgoing_set| {

            // iterate over outgoing edges
            var outgoing_entry_it = outgoing_set.iterator();

            while (outgoing_entry_it.next()) |entry| {
                const next = entry.key_ptr.*;

                // we have an edge value -> next

                // cannot fail: we know the edge (value, to_value) exists
                const incoming_map = incoming_edges.getPtr(next).?;

                {
                    const found = incoming_map.remove(value);
                    std.debug.assert(found);
                }

                if (incoming_map.count() == 0) {
                    // no more incoming edges for next
                    {
                        const found = incoming_edges.remove(next);
                        std.debug.assert(found);
                    }

                    // cannot fail: to_elem must be in unsorted section of elems // [next_unsorted_idx..]
                    const to_value_index = next_unsorted_idx + findIndex(elems[next_unsorted_idx..], next).?;

                    std.mem.swap(u8, &elems[next_unsorted_idx], &elems[to_value_index]);
                    next_unsorted_idx += 1;
                }
            }

            // remove all outgoing edges at once
            {
                const found = outgoing_edges.remove(value);
                std.debug.assert(found);
            }
        }
    }

    std.debug.assert(incoming_edges.count() == 0);
    std.debug.assert(outgoing_edges.count() == 0);
}

fn part1(alloc: std.mem.Allocator, reader: anytype) !u64 {
    var line_reader = utils.lineReader(alloc, reader);
    defer line_reader.deinit();

    var edges = std.AutoHashMap(Edge, void).init(alloc);
    defer edges.deinit();

    while (try line_reader.next()) |line| {
        if (line.len == 0) {
            break;
        }

        var it = utils.numberParserWithDelimiter(u8, line, '|');

        const from = (try it.next()).?;
        const to = (try it.next()).?;

        std.debug.assert((try it.next()) == null);

        try edges.put(.{ .from = from, .to = to }, {});
    }

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

        if (!isCorrectlyOrdered(update.items, edges)) {
            continue;
        }

        const middle_idx = update.items.len / 2;

        sum_middle_pages += update.items[middle_idx];
    }

    return sum_middle_pages;
}

fn part2(alloc: std.mem.Allocator, reader: anytype) !u64 {
    var line_reader = utils.lineReader(alloc, reader);
    defer line_reader.deinit();

    var edge_arena = std.heap.ArenaAllocator.init(alloc);
    defer edge_arena.deinit();

    var edges = std.AutoHashMap(Edge, void).init(alloc);
    defer edges.deinit();

    while (try line_reader.next()) |line| {
        if (line.len == 0) {
            break;
        }

        var it = utils.numberParserWithDelimiter(u8, line, '|');

        const from = (try it.next()).?;
        const to = (try it.next()).?;

        std.debug.assert((try it.next()) == null);

        try edges.put(.{ .from = from, .to = to }, {});
    }

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
            continue;
        }

        try topo_sort(edge_arena.allocator(), update.items, edges);

        const middle_idx = update.items.len / 2;

        sum_middle_pages += update.items[middle_idx];
    }

    return sum_middle_pages;
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

test "part2 example" {
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

    const result = try part2(alloc, stream.reader());

    try std.testing.expect(result == 123);
}

test "part2 input" {
    const alloc = std.testing.allocator;

    const filename = "inputs/day5.txt";

    const file_reader = try utils.FileReader.init(alloc, filename);
    defer file_reader.deinit();

    const result = try part2(alloc, file_reader.reader());

    try std.testing.expect(result == 4077);
}
