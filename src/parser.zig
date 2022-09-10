const std = @import("std");
const parseFloat = std.fmt.parseFloat;
const print = std.debug.print;
const todo = std.debug.todo;
const allocator = std.heap.page_allocator;
const ArrayList = std.ArrayList;

const TokenType = @import("token_type.zig").TokenType;
const Token = @import("token.zig").Token;
const Position = @import("token.zig").Position;

const ExprTag = enum {
    Binary,
    Unary,
    Number,
};

const UnaryExpr = struct {
    op: TokenType,
    rhs: *Expr,
};

const BinaryExpr = struct {
    lhs: *Expr,
    op: TokenType,
    rhs: *Expr,
};

const Expr = union(ExprTag) {
    Number: f64,
    Unary: UnaryExpr,
    Binary: BinaryExpr,
};

pub const Parser = struct {
    source: ArrayList(Token),
    start: usize,
    current: usize,
    line: usize,
    column: usize,

    pub fn new(source: ArrayList(Token)) Parser {
        return Parser{
            .source = source,
            .start = 0,
            .current = 0,
            .line = 0,
            .column = 9,
        };
    }

    fn is_at_end(self: *Parser) bool {
        return self.current >= self.source.items.len;
    }

    fn get_position(self: *Parser) Position {
        return Position.new(self.line, self.column);
    }

    fn increment_current(self: *Parser) void {
        self.current += 1;
        self.column += 1;
    }

    fn check(self: *Parser, expected: TokenType) bool {
        return if (self.is_at_end())
            false
        else
            self.source.items[self.current].token_type == expected;
    }

    fn peek(self: *Parser) ?Token {
        return if (self.is_at_end())
            null
        else
            self.source.items[self.current];
    }

    fn previous(self: *Parser) Token {
        return self.source.items[self.current - 1];
    }

    fn advance(self: *Parser) ?Token {
        if (self.is_at_end()) {
            return null;
        } else {
            var token: Token = self.source.items[self.current];
            self.increment_current();
            return token;
        }
    }

    fn match(self: *Parser, expected: TokenType) bool {
        if (self.check(expected)) {
            _ = self.advance();
            return true;
        }
        return false;
    }

    // add_or_
    // NUMBER -> NUMBER
    fn number(self: *Parser) ParserError!Expr {
        if (self.match(TokenType.Number)) {
            var num: f64 = parseFloat(f64, self.previous().lexeme);

            print("Number worked: {s},", .{num});
            return Expr{ .Number = num };
        }

        return ParserError.ExpectedNumber;
    }

    // unary -> "-" unary | NUMBER ;
    fn unary(self: *Parser) ParserError!Expr {
        if (self.match(TokenType.Minus)) {
            var rhs: Expr = try self.unary();
            var unary_expr = UnaryExpr{ .op = self.previous.?, .rhs = rhs };

            print("Unary worked: {s},", .{unary_expr});
            return Expr{ .Unary = &unary_expr };
        } else {
            return self.number();
        }
    }

    // factor -> factor ("/" | "*") NUMBER | NUMBER ;
    fn factor(self: *Parser) ParserError!Expr {
        var expr: Expr = try self.factor();

        while (self.match(TokenType.Slash) or self.match(TokenType.Star)) {
            var op = self.previous().token_type;
            var rhs: Expr = try self.factor();
            var bin_expr = BinaryExpr{ .lhs = &expr, .op = op, .rhs = &rhs };
            expr = Expr{ .Binary = bin_expr };
        }

        print("Factor worked: {s},", .{expr});
        return expr;
    }

    // term -> factor (("-" | "+") factor)* ;
    pub fn term(self: *Parser) ParserError!Expr {
        var expr: Expr = try self.factor();

        while (self.match(TokenType.Minus) or self.match(TokenType.Plus)) {
            var op = self.previous().token_type;
            var rhs: Expr = try self.factor();
            var bin_expr: BinaryExpr = BinaryExpr{ .lhs = &expr, .op = op, .rhs = &rhs };
            expr = Expr{ .Binary = bin_expr };
        }

        print("Factor worked: {s},", .{expr});
        return expr;
    }
};

pub const ParserError = error{
    ExpectedNumber,
};
