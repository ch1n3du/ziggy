const TokenType = @import("token.zig").TokenType;

pub const Expr = union(enum) {
    Number: f64,
    Unary: struct { op: TokenType, rhs: *Expr },
    Binary: struct { lhs: *Expr, op: TokenType, rhs: *Expr },

    pub fn evaluate(self: *Expr) f64 {
        switch (self.*) {
            .Number => |*n| {
                return n.*;
            },
            .Unary => |unary| {
                return -(unary.rhs.evaluate());
            },
            .Binary => |binary| {
                var lhs = binary.lhs.evaluate();
                var rhs = binary.rhs.evaluate();

                return switch (binary.op) {
                    .Plus => lhs + rhs,
                    .Minus => lhs - rhs,
                    .Star => lhs * rhs,
                    .Slash => lhs / rhs,
                    .Number => unreachable,
                };
            },
        }
    }
};
