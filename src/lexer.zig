const std = @import("std");
const testing = std.testing;
const expect = std.testing.expect;
const print = std.debug.print;

const token = @import("./token.zig");

const valid_chars = "a\x00b\x00c\x00d\x00e\x00f\x00g\x00h\x00i\x00j\x00k\x00l\x00m\x00n\x00o\x00p\x00q\x00r\x00s\x00t\x00u\x00v\x00w\x00x\x00y\x00z\x00A\x00B\x00C\x00D\x00E\x00F\x00G\x00H\x00I\x00J\x00K\x00L\x00M\x00N\x00O\x00P\x00Q\x00R\x00S\x00T\x00U\x00V\x00W\x00X\x00Y\x00Z\x00=\x00(\x00)\x00{\x00}\x00+\x00-\x00/\x00,\x00;\x00!\x00*\x00<\x00>\x00";

fn charToString(c: u8) [:0]const u8 {
    for (valid_chars) |e, i| {
        if (e == c) {
            return valid_chars[i..][0..1 :0]; // ':0' here asserts there's a 0 byte after the slice
        }
    }
    print("\n{s}\n", .{&[1]u8{c}});
    @panic("charToString(): letter is not part of ASCII");
}

fn newToken(token_type: []const u8, ch: u8) token.Token {
    return token.Token{ .type = token_type, .literal = charToString(ch) };
}

fn isLetter(ch: u8) bool {
    return 'a' <= ch and ch <= 'z' or 'A' <= ch and ch <= 'Z' or ch == '_';
}

fn isDigit(ch: u8) bool {
    return '0' <= ch and ch <= '9';
}

const Lexer = struct {
    input: []const u8,
    position: u32 = 0,
    read_position: u32 = 0,
    ch: u8 = 0,
    pub fn peekChar(self: Lexer) u8 {
        if (self.read_position >= self.input.len) {
            return 0;
        } else {
            return self.input[self.read_position];
        }
    }
    pub fn readIdentifier(self: *Lexer) []const u8 {
        const position = self.position;
        while (isLetter(self.ch)) {
            self.readChar();
        }

        return self.input[position..self.position];
    }

    pub fn readNumber(self: *Lexer) []const u8 {
        const position = self.position;
        while (isDigit(self.ch)) {
            self.readChar();
        }

        return self.input[position..self.position];
    }

    pub fn skipWhitespace(self: *Lexer) void {
        while (self.ch == ' ' or self.ch == '\t' or self.ch == '\n' or self.ch == '\r') {
            self.readChar();
        }
    }
    pub fn nextToken(self: *Lexer) token.Token {
        self.skipWhitespace();

        const tok =
            switch (self.ch) {
            '=' => blk: {
                if (self.peekChar() == '=') {
                    self.readChar();

                    break :blk token.Token{ .type = token.EQ, .literal = "==" };
                } else {
                    break :blk newToken(token.ASSIGN, self.ch);
                }
            },
            '+' => newToken(token.PLUS, self.ch),
            '-' => newToken(token.MINUS, self.ch),
            '*' => newToken(token.ASTERISK, self.ch),
            '/' => newToken(token.SLASH, self.ch),
            '<' => newToken(token.LT, self.ch),
            '>' => newToken(token.GT, self.ch),
            '!' => blk: {
                if (self.peekChar() == '=') {
                    self.readChar();

                    break :blk token.Token{ .type = token.NOT_EQ, .literal = "!=" };
                } else {
                    break :blk newToken(token.BANG, self.ch);
                }
            },
            '(' => newToken(token.LPAREN, self.ch),
            ')' => newToken(token.RPAREN, self.ch),
            '{' => newToken(token.LBRACE, self.ch),
            '}' => newToken(token.RBRACE, self.ch),
            ',' => newToken(token.COMMA, self.ch),
            ';' => newToken(token.SEMICOLON, self.ch),
            0 => blk: {
                break :blk token.Token{
                    .type = token.EOF,
                    .literal = "",
                };
            },
            else => blk: {
                if (isLetter(self.ch)) {
                    var identifier = self.readIdentifier();
                    return token.Token{ .literal = identifier, .type = token.lookupIdent(identifier) };
                } else if (isDigit(self.ch)) {
                    return token.Token{ .type = token.INT, .literal = self.readNumber() };
                } else {
                    break :blk newToken(token.ILLEGAL, self.ch);
                }
            },
        };

        self.readChar();

        return tok;
    }
    pub fn readChar(self: *Lexer) void {
        if (self.read_position >= self.input.len) {
            self.ch = 0;
        } else {
            self.ch = self.input[self.read_position];
        }

        self.position = self.read_position;
        self.read_position += 1;
    }
};

pub fn new(input: []const u8) Lexer {
    var l = Lexer{ .input = input };

    l.readChar();

    return l;
}

test "nextToken" {
    const input =
        \\let five = 5;
        \\let ten = 10;
        \\
        \\let add = fn(x, y) {
        \\  x + y;
        \\};
        \\
        \\let result = add(five, ten);
        \\!-/*5;
        \\5 < 10 > 5;
        \\
        \\if (5 < 10) {
        \\	return true;
        \\} else {
        \\	return false;
        \\}
        \\
        \\10 == 10;
        \\10 != 9;
    ;

    const Expectation = struct { expected_type: []const u8, expected_literal: []const u8 };
    const tests = [_]Expectation{
        .{ .expected_type = token.LET, .expected_literal = "let" },
        .{ .expected_type = token.IDENT, .expected_literal = "five" },
        .{ .expected_type = token.ASSIGN, .expected_literal = "=" },
        .{ .expected_type = token.INT, .expected_literal = "5" },
        .{ .expected_type = token.SEMICOLON, .expected_literal = ";" },

        .{ .expected_type = token.LET, .expected_literal = "let" },
        .{ .expected_type = token.IDENT, .expected_literal = "ten" },
        .{ .expected_type = token.ASSIGN, .expected_literal = "=" },
        .{ .expected_type = token.INT, .expected_literal = "10" },
        .{ .expected_type = token.SEMICOLON, .expected_literal = ";" },

        .{ .expected_type = token.LET, .expected_literal = "let" },
        .{ .expected_type = token.IDENT, .expected_literal = "add" },
        .{ .expected_type = token.ASSIGN, .expected_literal = "=" },
        .{ .expected_type = token.FUNCTION, .expected_literal = "fn" },
        .{ .expected_type = token.LPAREN, .expected_literal = "(" },
        .{ .expected_type = token.IDENT, .expected_literal = "x" },
        .{ .expected_type = token.COMMA, .expected_literal = "," },
        .{ .expected_type = token.IDENT, .expected_literal = "y" },
        .{ .expected_type = token.RPAREN, .expected_literal = ")" },
        .{ .expected_type = token.LBRACE, .expected_literal = "{" },
        .{ .expected_type = token.IDENT, .expected_literal = "x" },
        .{ .expected_type = token.PLUS, .expected_literal = "+" },
        .{ .expected_type = token.IDENT, .expected_literal = "y" },
        .{ .expected_type = token.SEMICOLON, .expected_literal = ";" },
        .{ .expected_type = token.RBRACE, .expected_literal = "}" },
        .{ .expected_type = token.SEMICOLON, .expected_literal = ";" },

        .{ .expected_type = token.LET, .expected_literal = "let" },
        .{ .expected_type = token.IDENT, .expected_literal = "result" },
        .{ .expected_type = token.ASSIGN, .expected_literal = "=" },
        .{ .expected_type = token.IDENT, .expected_literal = "add" },
        .{ .expected_type = token.LPAREN, .expected_literal = "(" },
        .{ .expected_type = token.IDENT, .expected_literal = "five" },
        .{ .expected_type = token.COMMA, .expected_literal = "," },
        .{ .expected_type = token.IDENT, .expected_literal = "ten" },
        .{ .expected_type = token.RPAREN, .expected_literal = ")" },
        .{ .expected_type = token.SEMICOLON, .expected_literal = ";" },

        .{ .expected_type = token.BANG, .expected_literal = "!" },
        .{ .expected_type = token.MINUS, .expected_literal = "-" },
        .{ .expected_type = token.SLASH, .expected_literal = "/" },
        .{ .expected_type = token.ASTERISK, .expected_literal = "*" },
        .{ .expected_type = token.INT, .expected_literal = "5" },
        .{ .expected_type = token.SEMICOLON, .expected_literal = ";" },
        .{ .expected_type = token.INT, .expected_literal = "5" },
        .{ .expected_type = token.LT, .expected_literal = "<" },
        .{ .expected_type = token.INT, .expected_literal = "10" },
        .{ .expected_type = token.GT, .expected_literal = ">" },
        .{ .expected_type = token.INT, .expected_literal = "5" },
        .{ .expected_type = token.SEMICOLON, .expected_literal = ";" },

        .{ .expected_type = token.IF, .expected_literal = "if" },
        .{ .expected_type = token.LPAREN, .expected_literal = "(" },
        .{ .expected_type = token.INT, .expected_literal = "5" },
        .{ .expected_type = token.LT, .expected_literal = "<" },
        .{ .expected_type = token.INT, .expected_literal = "10" },
        .{ .expected_type = token.RPAREN, .expected_literal = ")" },
        .{ .expected_type = token.LBRACE, .expected_literal = "{" },
        .{ .expected_type = token.RETURN, .expected_literal = "return" },
        .{ .expected_type = token.TRUE, .expected_literal = "true" },
        .{ .expected_type = token.SEMICOLON, .expected_literal = ";" },
        .{ .expected_type = token.RBRACE, .expected_literal = "}" },
        .{ .expected_type = token.ELSE, .expected_literal = "else" },
        .{ .expected_type = token.LBRACE, .expected_literal = "{" },
        .{ .expected_type = token.RETURN, .expected_literal = "return" },
        .{ .expected_type = token.FALSE, .expected_literal = "false" },
        .{ .expected_type = token.SEMICOLON, .expected_literal = ";" },
        .{ .expected_type = token.RBRACE, .expected_literal = "}" },

        .{ .expected_type = token.INT, .expected_literal = "10" },
        .{ .expected_type = token.EQ, .expected_literal = "==" },
        .{ .expected_type = token.INT, .expected_literal = "10" },
        .{ .expected_type = token.SEMICOLON, .expected_literal = ";" },
        .{ .expected_type = token.INT, .expected_literal = "10" },
        .{ .expected_type = token.NOT_EQ, .expected_literal = "!=" },
        .{ .expected_type = token.INT, .expected_literal = "9" },
        .{ .expected_type = token.SEMICOLON, .expected_literal = ";" },

        .{ .expected_type = token.EOF, .expected_literal = "" },
    };
    var tok: token.Token = undefined;

    var l = new(input);

    for (tests) |t| {
        tok = l.nextToken();

        try std.testing.expectEqualStrings(t.expected_type, tok.type);
        try std.testing.expectEqualStrings(t.expected_literal, tok.literal);
    }
}
