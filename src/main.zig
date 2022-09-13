const std = @import("std");
const print = std.debug.print;
const expect = @import("std").testing.expect;

const TokenType = @import("token_type.zig").TokenType;
const Token = @import("token.zig").Token;
const Scanner = @import("scanner.zig").Scanner;
const Parser = @import("parser.zig").Parser;

pub fn main() void {
    var scanny = Scanner.new("4.3223 + 93 + 3");
    var tokens = scanny.scan_tokens();
    // print("{s}", .{tokens});
    var parsy = Parser.new(tokens);
    // print("{s}", .{parsy});
    var expr = parsy.term();
    print("Successfully parsed: {s}", .{expr});
    print("Hello\n", .{});
}
