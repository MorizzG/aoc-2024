const std = @import("std");

pub const FileReader = struct {
    const BufferedReader = std.io.BufferedReader(4096, std.fs.File.Reader);
    const Reader = std.io.Reader(*BufferedReader, std.fs.File.Reader.Error, BufferedReader.read);

    alloc: std.mem.Allocator,

    file: std.fs.File,

    buf_reader_ptr: *BufferedReader,

    pub fn init(alloc: std.mem.Allocator, filename: []const u8) !FileReader {
        const file = try std.fs.cwd().openFile(filename, .{});

        const file_reader = file.reader();

        const buf_reader_ptr = try alloc.create(BufferedReader);
        buf_reader_ptr.* = std.io.bufferedReader(file_reader);

        return .{
            .alloc = alloc,
            .file = file,
            .buf_reader_ptr = buf_reader_ptr,
        };
    }

    pub fn deinit(self: FileReader) void {
        self.file.close();

        self.alloc.destroy(self.buf_reader_ptr);
    }

    pub fn reader(self: FileReader) Reader {
        return Reader{ .context = self.buf_reader_ptr };
    }
};

pub fn LineReader(comptime ReaderType: type) type {
    return struct {
        const Self = @This();

        reader: ReaderType,

        line_buf: std.ArrayList(u8),

        pub fn init(alloc: std.mem.Allocator, reader: ReaderType) Self {
            const line_buf = std.ArrayList(u8).init(alloc);

            return .{
                .reader = reader,
                .line_buf = line_buf,
            };
        }

        pub fn deinit(self: *Self) void {
            self.line_buf.deinit();
        }

        pub fn next(self: *Self) !?[]u8 {
            self.line_buf.clearRetainingCapacity();

            self.reader.streamUntilDelimiter(self.line_buf.writer(), '\n', 4096) catch |err| switch (err) {
                error.EndOfStream => if (self.line_buf.items.len == 0) {
                    // the first time we get an EndOfStream we return the content of the line_buf,
                    // the second time we're finished
                    return null;
                },
                else => return err,
            };

            return self.line_buf.items;
        }
    };
}

pub fn lineReader(alloc: std.mem.Allocator, reader: anytype) LineReader(@TypeOf(reader)) {
    return LineReader(@TypeOf(reader)).init(alloc, reader);
}

pub fn NumberParser(comptime T: type) type {
    return struct {
        token_it: std.mem.TokenIterator(u8, .scalar),

        pub fn next(self: *@This()) !?T {
            if (self.token_it.next()) |tok| {
                return try std.fmt.parseUnsigned(T, tok, 10);
            }

            return null;
        }
    };
}

pub fn numberParserWithDelimiter(comptime T: type, input: []const u8, delimiter: u8) NumberParser(T) {
    const input_trimmed = std.mem.trim(u8, input, "\n");

    return NumberParser(T){ .token_it = std.mem.tokenizeScalar(u8, input_trimmed, delimiter) };
}

pub fn numberParser(comptime T: type, input: []const u8) NumberParser(T) {
    return numberParserWithDelimiter(T, input, ' ');
}

pub fn allocGrid(comptime T: type, alloc: std.mem.Allocator, n: usize, m: usize) ![][]T {
    const grid = try alloc.alloc([]T, n);

    for (grid) |*line| {
        line.* = try alloc.alloc(T, m);
    }

    return grid;
}

pub fn allocGridInit(comptime T: type, alloc: std.mem.Allocator, n: usize, m: usize, init: T) ![][]T {
    const grid = try alloc.alloc([]T, n);

    for (grid) |*line| {
        line.* = try alloc.alloc(T, m);

        for (line.*) |*x| {
            x.* = init;
        }
    }

    return grid;
}

pub fn deinitGrid(comptime T: type, alloc: std.mem.Allocator, grid: [][]T) void {
    for (grid) |line| {
        alloc.free(line);
    }

    alloc.free(grid);
}

pub fn rangeComptime(comptime n: usize) [n]usize {
    var array: [n]usize = undefined;

    for (0.., &array) |i, *elem| {
        elem.* = i;
    }

    return array;
}

pub fn range(alloc: std.mem.Allocator, n: usize) ![]usize {
    var array = try alloc.alloc(usize, n);

    for (0..n) |i| {
        array[i] = i;
    }

    return array;
}

pub fn printSlice(comptime T: type, slice: []const T) void {
    if (slice.len == 0) {
        std.debug.print("[ ]", .{});
        return;
    }

    std.debug.print("[ ", .{});

    for (slice[0 .. slice.len - 1]) |x| {
        std.debug.print("{}, ", .{x});
    }

    std.debug.print("{} ]", .{slice[slice.len - 1]});
}

pub fn printlnSlice(comptime T: type, slice: []const T) void {
    if (slice.len == 0) {
        std.debug.print("[ ]\n", .{});
        return;
    }

    std.debug.print("[ ", .{});

    for (slice[0 .. slice.len - 1]) |x| {
        std.debug.print("{}, ", .{x});
    }

    std.debug.print("{} ]\n", .{slice[slice.len - 1]});
}

pub fn num_digits(n: anytype) std.math.Log2Int(@TypeOf(n)) {
    return std.math.log10_int(n) + 1;
}

test "num_digits" {
    // try std.fmt.allocPrint(
    //     std.testing.allocator,
    //     "Expected {} to have 4 digit, but got {} instead",
    //     .{ n, num_digits },
    // );

    for (2..10) |n| {
        try std.testing.expectEqual(num_digits(n), 1);
    }

    for (10..100) |n| {
        try std.testing.expectEqual(num_digits(n), 2);
    }

    for (100..1_000) |n| {
        try std.testing.expectEqual(num_digits(n), 3);
    }

    for (1_000..10_000) |n| {
        try std.testing.expectEqual(num_digits(n), 4);
    }
}
