const std = @import("std");
const expect = std.testing.expect;
const print = std.debug.print;
const panic = std.debug.panic;
const ArrayList = std.ArrayList;
const allocator = std.heap.page_allocator;

const Token = @import("token.zig").Token;
const TokenType = @import("token.zig").TokenType;
const Position = @import("token.zig").Position;

const ScannerError = error{
    ExpectedNumber,
};

pub const Scanner = struct {
    source: []const u8,
    tokens: ArrayList(Token),
    start: usize,
    current: usize,
    line: usize,
    column: usize,

    pub fn new(source: []const u8) Scanner {
        return Scanner{
            .source = source,
            .tokens = ArrayList(Token).init(allocator),
            .start = 0,
            .current = 0,
            .line = 0,
            .column = 9,
        };
    }

    fn is_at_end(self: *Scanner) bool {
        return self.current >= self.source.len;
    }

    fn get_position(self: *Scanner) Position {
        return Position.new(self.line, self.column);
    }

    fn increment_current(self: *Scanner) void {
        self.current += 1;
        self.column += 1;
    }

    fn check(self: *Scanner, expected: u8) bool {
        return if (self.is_at_end())
            false
        else
            self.source[self.current] == expected;
    }

    fn peek(self: *Scanner) ?u8 {
        return if (self.is_at_end())
            null
        else
            self.source[self.current];
    }

    fn advance(self: *Scanner) ?u8 {
        if (self.is_at_end()) {
            return null;
        } else {
            var lexeme: u8 = self.source[self.current];
            self.increment_current();
            return lexeme;
        }
    }

    fn match(self: *Scanner, expected: u8) bool {
        if (self.check(expected)) {
            _ = self.advance();
            return true;
        }
        return false;
    }

    fn get_token(self: *Scanner, token_type: TokenType) Token {
        var lexeme = self.source[self.start..self.current];
        var position = self.get_position();

        var token = Token.new(token_type, lexeme, position);

        return token;
    }

    fn scan_number(self: *Scanner) Token {
        var lexy = self.peek() orelse 2;

        while (!self.is_at_end() and is_numeric(lexy)) {
            _ = self.advance();
            // var lex = self.advance();
            // print("Scanning: '{c}'\n", .{lex});
            lexy = self.peek() orelse 2;
        }

        if (self.match('.')) {
            // print("Scanning: '.'", .{});
            lexy = self.peek() orelse 2;
            while (!self.is_at_end() and is_numeric(lexy)) {
                _ = self.advance();
                // var lex = self.advance();
                // print("Scanning: '{c}'\n", .{lex});
                lexy = self.peek() orelse 2;
            }
        }

        return self.get_token(TokenType.Number);
    }

    fn scan_token(self: *Scanner) ?Token {
        var lexy = self.advance() orelse return null;
        // print("Scanning: '{c}'\n", .{lexy});
        var token: ?Token = null;

        token = switch (lexy) {
            '+' => self.get_token(TokenType.Plus),
            '-' => self.get_token(TokenType.Minus),
            '/' => self.get_token(TokenType.Slash),
            '*' => self.get_token(TokenType.Star),
            '\n' => {
                self.line += 1;
                return null;
            },
            else => {
                if (is_numeric(lexy)) {
                    return self.scan_number();
                } else {
                    return null;
                }
            },
        };

        return token;
    }

    pub fn scan_tokens(self: *Scanner) ArrayList(Token) {
        var tokens = ArrayList(Token).init(allocator);

        while (!self.is_at_end()) {
            self.start = self.current;
            var token_: ?Token = self.scan_token();
            if (token_) |value| {
                tokens.append(value) catch {};
            } else {
                continue;
            }
        }

        return tokens;
    }
};

fn is_numeric(c: u8) bool {
    return (c > 47) and (c < 58);
}

fn is_upper(c: u8) bool {
    return (c > 64) and (c < 91);
}

fn is_lower(c: u8) bool {
    return (c > 96) and (c < 123);
}

fn is_alpha(c: u8) bool {
    return is_lower(c) or is_upper(c);
}

test "Advance works" {
    var src = "12 + 43";
    var scanny: Scanner = Scanner.new(src);

    try expect(scanny.check(src[0]));

    var lexy: u8 = scanny.advance() orelse 42;

    try expect(scanny.current == 1);
    try expect(lexy == src[0]);
    try expect(is_numeric(src[0]));
    try expect(scanny.scan_tokens().items.len == 3);
}

test "Alphabetic predicates work" {
    const lowers = "abcdefghijklmnopqrstuvwxyz";
    const uppers = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
    const numerics = "1234567890";

    for (lowers) |char| {
        try expect(is_lower(char));
    }

    for (uppers) |char| {
        try expect(is_upper(char));
    }

    for (numerics) |char| {
        try expect(is_numeric(char));
    }
}
