const token = @import("./token.zig");
const lexer = @import("./lexer.zig");

const std = @import("std");
const builtin = @import("builtin");

const PROMPT = ">> ";

const stderr = std.io.getStdErr().writer();

fn nextLine(reader: anytype, buffer: []u8) ?[]const u8 {
    if (reader.readUntilDelimiterOrEof(buffer, '\n') catch {
        return null;
    }) |line| {
        return line;
    } else {
        return null;
    }
}

pub fn start(in: anytype, out: anytype) !void {
    var repl_buf: [1024]u8 = undefined;

    while (true) {
        try out.writeAll(PROMPT);

        const line = nextLine(in, &repl_buf).?;

        var lex = lexer.new(line);

        var tok: token.Token = lex.nextToken();

        while (!std.mem.eql(u8, tok.type, token.EOF)) : (tok = lex.nextToken()) {
            try out.print("{}\n", .{tok});
        }
    }
}
