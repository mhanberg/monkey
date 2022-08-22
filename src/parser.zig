const std = @import("std");
const expect = std.testing.expect;

const ast = @import("./ast.zig");
const lexer = @import("./lexer.zig");
const token = @import("./token.zig");

const Parser = struct {
    l: *lexer.Lexer,
    curToken: token.Token = undefined,
    peekToken: token.Token = undefined,

    fn nextToken(self: *Parser) void {
        self.curToken = self.peekToken;
        self.peekToken = self.l.nextToken();
    }

    fn parseProgram(_: Parser) ?ast.Program {
        return null;
    }
};

pub fn new(l: *lexer.Lexer) Parser {
    var p = Parser{ .l = l };

    p.nextToken();
    p.nextToken();

    return p;
}

test "let statements" {
    const input =
        \\let x = 5;
        \\let y = 10;
        \\let foobar = 838383;
    ;

    var lex = lexer.new(input);
    var pars = new(&lex);

    var prog: ?ast.Program = pars.parseProgram();

    try expect(prog != null);
    try std.testing.expectEqual(prog.?.statements.len, 3);

    const Expectation = struct { expected_identifier: []const u8 };

    const tests = [_]Expectation{
        .{ .expected_identifier = "x" },
        .{ .expected_identifier = "y" },
        .{ .expected_identifier = "foobar" },
    };

    for (tests) |t, i| {
        const statement = prog.?.statements[i];

        try expect(try testLetStatement(statement, t.expected_identifier));
    }
}

fn testLetStatement(s: ast.Statement, _: []const u8) !bool {
    try std.testing.expectEqual(s.tokenLiteral(), "let");

    return true;
}
