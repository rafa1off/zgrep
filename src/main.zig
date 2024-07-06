const std = @import("std");
const lib = @import("root.zig");

pub fn main() !void {
    const config = lib.readArgs() catch |err| {
        switch (err) {
            lib.Invoke.ArgAlloc => {
                std.debug.print("Error allocating args\n", .{});
            },
            lib.Invoke.NotEnoughArgs => {
                std.debug.print("Not enough args. Usage: zgrep <query> <path>\n", .{});
            },
            lib.Invoke.TooManyArgs => {
                std.debug.print("Too many args. Usage: zgrep <query> <path>\n", .{});
            },
        }
        return;
    };

    lib.search(config) catch |err| {
        std.debug.print("error reading file: {any}\n", .{err});
    };
}
