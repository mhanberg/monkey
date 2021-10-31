const std = @import("std");
const repl = @import("./repl.zig");

pub fn main() anyerror!void {
    const stdin = std.io.getStdIn().reader();
    const stdout = std.io.getStdOut().writer();

    try stdout.writeAll("Hello Mitch! this is the Monkey programming language!\n");
    try stdout.writeAll("Feel free to type in commands\n");

    try repl.start(stdin, stdout);
}
