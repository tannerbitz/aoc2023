const std = @import("std");
const Allocator = std.mem.Allocator;

const Draw = struct {
    red: usize,
    green: usize,
    blue: usize,
};
const Game = struct {
    const Self = @This();

    id: usize,
    draws: std.ArrayList(Draw),

    fn init(allocator: Allocator) Self {
        return .{
            .id = 0,
            .draws = std.ArrayList(Draw).init(allocator),
        };
    }

    fn deinit(self: Self) void {
        self.draws.deinit();
    }
};

fn parseGame(input: []const u8, allocator: Allocator) !Game {
    const idx = std.mem.indexOf(u8, input, ":");
    const game_str: []const u8 = input[0..idx.?];
    const draws_str: []const u8 = input[idx.? + 1 ..];

    std.debug.print("'{s}' || '{s}'\n", .{ game_str, draws_str });
    return Game.init(allocator);
}

pub fn main() !void {
    var file = try std.fs.cwd().openFile("input.txt", .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var buf: [1024]u8 = undefined;

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    const allocator = arena.allocator();

    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        const game = try parseGame(line, allocator);
        defer game.deinit();
    }
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
