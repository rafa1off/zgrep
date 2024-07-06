const std = @import("std");

pub const Invoke = error{
    ArgAlloc,
    NotEnoughArgs,
    TooManyArgs,
};

pub const Config = struct {
    query: []const u8,
    path: []const u8,

    const Self = @This();

    pub fn init(query: []const u8, path: []const u8) Self {
        return .{
            .query = query,
            .path = path,
        };
    }
};

pub fn readArgs() Invoke!Config {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();

    var it = std.process.argsWithAllocator(alloc) catch return Invoke.ArgAlloc;
    defer it.deinit();

    _ = it.next();

    const query = it.next() orelse return Invoke.NotEnoughArgs;
    const path = it.next() orelse return Invoke.NotEnoughArgs;
    if (it.next() != null) return Invoke.TooManyArgs;

    return Config.init(query, path);
}

pub fn search(config: Config) !void {
    var file = try std.fs.cwd().openFile(config.path, .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var reader = buf_reader.reader();

    var buf: [1024]u8 = undefined;
    while (try reader.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        if (std.mem.count(u8, line, config.query) > 0) {
            std.debug.print("{s}\n", .{line});
        }
    }
}
