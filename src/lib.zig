const std = @import("std");

pub const InvokeError = error{
    ArgAlloc,
    NotEnoughArgs,
    TooManyArgs,
};

pub const Config = struct {
    query: []const u8,
    path: []const u8,

    const Self = @This();

    fn init(query: []const u8, path: []const u8) Self {
        return .{
            .query = query,
            .path = path,
        };
    }

    pub fn search(self: Self) !void {
        var file = try std.fs.cwd().openFile(self.path, .{});
        defer file.close();

        var buf_reader = std.io.bufferedReader(file.reader());
        var reader = buf_reader.reader();

        const stdout_file = std.io.getStdOut().writer();
        var buf_writer = std.io.bufferedWriter(stdout_file);
        const stdout = buf_writer.writer();

        var buf: [1024]u8 = undefined;
        while (try reader.readUntilDelimiterOrEof(&buf, '\n')) |line| {
            if (std.mem.count(u8, line, self.query) > 0) {
                try stdout.print("{s}\n", .{line});
            }
        }

        try buf_writer.flush();
    }
};

pub fn readArgs() InvokeError!Config {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();

    var it = std.process.argsWithAllocator(alloc) catch return InvokeError.ArgAlloc;
    defer it.deinit();

    _ = it.next();

    const query = it.next() orelse return InvokeError.NotEnoughArgs;
    const path = it.next() orelse return InvokeError.NotEnoughArgs;
    if (it.next() != null) return InvokeError.TooManyArgs;

    return Config.init(query, path);
}
