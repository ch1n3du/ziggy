const std = @import("std");
const parseFloat = std.fmt.parseFloat;
const print = std.debug.print;
const todo = std.debug.todo;
const allocator = std.heap.page_allocator;
const ArrayList = std.ArrayList;

const Token = @import("token.zig").Token;
const TokenType = @import("token.zig").TokenType;
const Position = @import("token.zig").Position;
const Expr = @import("expr.zig").Expr;

const ExprTag = enum {
    Binary,
    Unary,
    Number,
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
    fn number(self: *Parser) anyerror!Expr {
        if (self.match(TokenType.Number)) {
            var num: f64 = try parseFloat(f64, self.previous().lexeme);

            return Expr{ .Number = num };
        }

        return ParserError.ExpectedNumber;
    }

    // unary -> "-" unary | NUMBER ;
    fn unary(self: *Parser) anyerror!Expr {
        if (self.match(TokenType.Minus)) {
            var rhs: *Expr = try allocator.create(Expr);
            rhs.* = try self.unary();
            return Expr{ .Unary = .{ .op = TokenType.Minus, .rhs = rhs } };
        } else {
            return self.number();
        }
    }

    // factor -> unary (("/" | "*") NUMBER)* ;
    fn factor(self: *Parser) anyerror!Expr {
        var expr: Expr = try self.unary();

        while (self.match(TokenType.Slash) or self.match(TokenType.Star)) {
            var lhs: *Expr = try allocator.create(Expr);
            lhs.* = expr;

            var op = self.previous().token_type;

            var rhs: *Expr = try allocator.create(Expr);
            rhs.* = try self.number();

            expr = Expr{ .Binary = .{ .lhs = lhs, .op = op, .rhs = rhs } };
        }

        return expr;
    }

    // term -> factor (("-" | "+") factor)* ;
    pub fn term(self: *Parser) anyerror!Expr {
        var expr: Expr = try self.factor();

        while (self.match(TokenType.Minus) or self.match(TokenType.Plus)) {
            var lhs: *Expr = try allocator.create(Expr);
            lhs.* = expr;

            var op = self.previous().token_type;

            var rhs: *Expr = try allocator.create(Expr);
            rhs.* = try self.factor();

            expr = Expr{ .Binary = .{ .lhs = lhs, .op = op, .rhs = rhs } };
        }

        return expr;
    }
};

pub const ParserError = error{
    ExpectedNumber,
};
