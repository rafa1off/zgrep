const std = @import("std");

pub const InvokeError = error{
    ArgAlloc,
    NotEnoughArgs,
    TooManyArgs,
    InvalidArg,
};

pub const Config = struct {
    query: []const u8,

    const Self = @This();

    fn init(query: []const u8) Self {
        return .{
            .query = query,
        };
    }

    pub fn run(self: Self) !void {
        var dir = try std.fs.cwd().openDir(".", .{ .iterate = true });
        defer dir.close();
        try iterateDir(dir, self.query);
    }
};

pub fn readArgs() InvokeError!Config {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();

    var it = std.process.argsWithAllocator(alloc) catch return InvokeError.ArgAlloc;
    defer it.deinit();

    _ = it.next();

    const query = it.next() orelse return InvokeError.NotEnoughArgs;
    if (it.next() != null) return InvokeError.TooManyArgs;

    if (query.len == 0) return InvokeError.InvalidArg;

    return Config.init(query);
}

fn search(file: std.fs.File, query: []const u8, name: []const u8) !void {
    var buf_reader = std.io.bufferedReader(file.reader());
    var reader = buf_reader.reader();

    const stdout_file = std.io.getStdOut().writer();
    var buf_writer = std.io.bufferedWriter(stdout_file);
    const stdout = buf_writer.writer();

    var buf: [1024]u8 = undefined;
    while (try reader.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        if (std.mem.count(u8, line, query) > 0) {
            try stdout.print("{s}\n", .{name});
            break;
        }
    }

    try buf_writer.flush();
}

pub fn iterateDir(dir: std.fs.Dir, query: []const u8) !void {
    var it = dir.iterate();

    while (try it.next()) |entry| {
        switch (entry.kind) {
            std.fs.File.Kind.file => {
                const file = try std.fs.cwd().openFile(entry.name, .{});
                try search(file, query, entry.name);
                file.close();
            },
            std.fs.File.Kind.directory => {
                std.debug.print("{s}\n", .{entry.name});
                // var sub_dir = try dir.openDir(entry.name, .{ .iterate = true });
                // try iterateDir(sub_dir, query);
                // sub_dir.close();
            },
            else => continue,
        }
    }
}
