const std = @import("std");
const zg = @import("lib.zig");

pub fn main() !void {
    const config = zg.readArgs() catch |err| switch (err) {
        zg.InvokeError.ArgAlloc => {
            std.debug.print("Error allocating args\n", .{});
            return;
        },
        zg.InvokeError.NotEnoughArgs => {
            std.debug.print("Not enough args. Usage: zgrep <query> <path>\n", .{});
            return;
        },
        zg.InvokeError.TooManyArgs => {
            std.debug.print("Too many args. Usage: zgrep <query> <path>\n", .{});
            return;
        },
    };

    config.search() catch |err| {
        std.debug.print("Error reading file: {any}\n", .{err});
    };
}
