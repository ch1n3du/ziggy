const std = @import("std");
const print = std.debug.print;
const expect = @import("std").testing.expect;

const Token = @import("token.zig").Token;
const Scanner = @import("scanner.zig").Scanner;
const Parser = @import("parser.zig").Parser;

pub fn main() anyerror!void {
    var scanny = Scanner.new("93 + 3");
    var tokens = scanny.scan_tokens();
    var parsy = Parser.new(tokens);
    var expr = try parsy.term();
    print("Successfully Evaluated: {d}\n", .{expr.evaluate()});
    print("Hello\n", .{});
}
