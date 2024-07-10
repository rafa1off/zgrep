const std = @import("std");
const mem = std.mem;
const heap = std.heap;
const io = std.io;
const fs = std.fs;
const process = std.process;

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
        const stdout_file = io.getStdOut().writer();
        var buf_writer = io.bufferedWriter(stdout_file);
        const stdout = buf_writer.writer();

        var dir = try fs.cwd().openDir(".", .{ .iterate = true });
        defer dir.close();
        try iterateDir(dir, self.query, stdout);

        try buf_writer.flush();
    }
};

pub fn readArgs() InvokeError!Config {
    var gpa = heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();

    var it = process.argsWithAllocator(alloc) catch return InvokeError.ArgAlloc;
    defer it.deinit();

    _ = it.next();

    const query = it.next() orelse return InvokeError.NotEnoughArgs;
    if (it.next() != null) return InvokeError.TooManyArgs;

    if (query.len == 0) return InvokeError.InvalidArg;

    return Config.init(query);
}

fn search(file: fs.File, query: []const u8, name: []const u8, stdout: anytype) !void {
    var buf_reader = io.bufferedReader(file.reader());
    var reader = buf_reader.reader();

    var buf: [1024 * 1024]u8 = undefined;
    var count: usize = 0;

    while (reader.skipBytes(count, .{}) != error.EndOfStream) {
        count += try reader.readAtLeast(&buf, buf.len);
        if (mem.count(u8, &buf, query) > 0) {
            try stdout.print("{s}\n", .{name});
            break;
        }
    }
}

pub fn iterateDir(dir: fs.Dir, query: []const u8, writer: anytype) !void {
    var it = dir.iterate();

    while (try it.next()) |entry| {
        switch (entry.kind) {
            fs.File.Kind.file => {
                const file = dir.openFile(entry.name, .{}) catch |err| switch (err) {
                    error.AccessDenied, error.DeviceBusy => continue,
                    else => return err,
                };
                try search(file, query, entry.name, writer);
                file.close();
            },
            fs.File.Kind.directory => {
                if (mem.count(u8, entry.name, ".git") > 0 or
                    mem.count(u8, entry.name, "bin") > 0 or
                    mem.count(u8, entry.name, ".cache") > 0 or
                    mem.count(u8, entry.name, "cache") > 0)
                {
                    continue;
                }

                var sub_dir = dir.openDir(entry.name, .{ .iterate = true }) catch |err| switch (err) {
                    error.AccessDenied, error.DeviceBusy => continue,
                    else => return err,
                };
                try iterateDir(sub_dir, query, writer);
                sub_dir.close();
            },
            else => continue,
        }
    }
}
