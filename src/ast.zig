const token = @import("./token.zig");

// const Interface = struct {
//     // pointer to the implementing struct (we don't know the type)
//     impl: *c_void,

//     // can call directly: iface.pickFn(iface.impl)
//     pickFn: fn (*c_void) i32,

//     // allows calling: iface.pick()
//     pub fn pick(iface: *const Interface) i32 {
//         return iface.pickFn(iface.impl);
//     }
// };

const Node = struct {
    impl: *c_void,

    // can call directly: iface.tokenLiteralFn(iface)
    tokenLiteralFn: fn (*Node) i32,

    // allows calling: iface.tokenLiteral()
    pub fn tokenLiteral(iface: *const Node) i32 {
        return iface.tokenLiteralFn(iface.impl);
    }
};

pub const Statement = struct {
    impl: *c_void,
    // can call directly: iface.tokenLiteralFn(iface)
    tokenLiteralFn: fn (*Statement) i32,
    // can call directly: iface.tokenLiteralFn(iface)
    statementNodeFn: fn (*Statement) i32,

    pub fn tokenLiteral(iface: *const Statement) i32 {
        return iface.tokenLiteralFn(iface.impl);
    }

    pub fn statementNode(iface: *const Statement) i32 {
        return iface.statementNodeFn(iface.impl);
    }
};

const Expression = struct {
    impl: *c_void,
    // can call directly: iface.tokenLiteralFn(iface)
    tokenLiteralFn: fn (*Expression) i32,
    // can call directly: iface.tokenLiteralFn(iface)
    expressionNodeFn: fn (*Expression) i32,

    // allows calling: iface.tokenLiteral()
    pub fn tokenLiteral(iface: *const Expression) i32 {
        return iface.tokenLiteralFn(iface.impl);
    }

    // allows calling: iface.expressionNode()
    pub fn expressionNode(iface: *const Expression) i32 {
        return iface.expressionNodeFn(iface.impl);
    }
};

pub const Program = struct {
    statements: []Statement,

    fn init(statements: []Statement) Program {
        return .{ .statements = statements };
    }

    fn interface(self: *Program) Node {
        return .{
            .impl = @ptrCast(*c_void, self),
            .tokenLiteralFn = tokenLiteral,
        };
    }

    fn tokenLiteral(self_void: *c_void) []const u8 {
        var self = @ptrCast(*Program, @alignCast(@alignOf(Program), self_void));

        if (self.statements.len > 0) {
            return self.statements[0].tokenLiteral();
        } else {
            return "";
        }
    }
};

const LetStatement = struct {
    token: token.Token,
    name: *Identifier,
    value: Expression,

    fn init(tok: token.Token, name: *Identifier, value: Expression) Program {
        return .{
            .token = tok,
            .name = name,
            .value = value,
        };
    }

    fn interface(self: *LetStatement) Statement {
        return .{
            .impl = @ptrCast(*c_void, self),
            .tokenLiteralFn = tokenLiteral,
            .statementNodeFn = statementNode,
        };
    }

    pub fn statementNode(_: *c_void) void {}
    pub fn tokenLiteral(self_void: *c_void) []const u8 {
        var self = @ptrCast(*LetStatement, @alignCast(@alignOf(LetStatement), self_void));

        return self.token.literal;
    }
};

const Identifier = struct {
    token: token.Token,
    value: []const u8,

    fn init(tok: token.Token, value: Expression) Identifier {
        return .{
            .token = tok,
            .value = value,
        };
    }

    fn interface(self: *Identifier) Statement {
        return .{
            .impl = @ptrCast(*c_void, self),
            .tokenLiteralFn = tokenLiteral,
        };
    }
    pub fn expressionNode(_: *c_void) void {}
    pub fn tokenLiteral(self_void: *c_void) []const u8 {
        var self = @ptrCast(*Identifier, @alignCast(@alignOf(Identifier), self_void));
        return self.token.literal;
    }
};
