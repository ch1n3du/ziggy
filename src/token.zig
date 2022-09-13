pub const Token = struct {
    token_type: TokenType,
    lexeme: []const u8,
    position: Position,

    pub fn new(token_type: TokenType, lexeme: []const u8, position: Position) Token {
        return Token{
            .token_type = token_type,
            .lexeme = lexeme,
            .position = position,
        };
    }
};

pub const TokenType = enum {
    Plus,
    Minus,
    Slash,
    Star,
    Number,
};

pub const Position = struct {
    line: usize,
    column: usize,

    pub fn new(line: usize, column: usize) Position {
        return Position{ .line = line, .column = column };
    }
};
