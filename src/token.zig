const std = @import("std");

pub const ILLEGAL = "illegal";
pub const EOF = "eof";
pub const IDENT = "ident";
pub const INT = "int";

// operators
pub const ASSIGN = "=";
pub const PLUS = "+";
pub const MINUS = "-";
pub const BANG = "!";
pub const ASTERISK = "*";
pub const SLASH = "/";
pub const LT = "<";
pub const GT = ">";

pub const EQ = "==";
pub const NOT_EQ = "!=";

pub const COMMA = ",";
pub const SEMICOLON = ";";
pub const LPAREN = "(";
pub const RPAREN = ")";
pub const LBRACE = "{";
pub const RBRACE = "}";

pub const FUNCTION = "function";
pub const LET = "let";
pub const TRUE = "true";
pub const FALSE = "false";
pub const IF = "if";
pub const ELSE = "else";
pub const RETURN = "return";

pub const Token = struct {
    type: []const u8,
    literal: []const u8,
    pub fn format(
        self: Token,
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = fmt;
        _ = options;

        try writer.print("Token{{ .type = \"{s}\", .literal = \"{s}\" }}", .{ self.type, self.literal });
    }
};

const keywords = std.ComptimeStringMap([]const u8, .{
    &.{ "fn", FUNCTION },
    &.{ "let", LET },
    &.{ "true", TRUE },
    &.{ "false", FALSE },
    &.{ "if", IF },
    &.{ "else", ELSE },
    &.{ "return", RETURN },
});

pub fn lookupIdent(identifier: []const u8) []const u8 {
    if (keywords.get(identifier)) |tok| {
        return tok;
    } else {
        return IDENT;
    }
}
