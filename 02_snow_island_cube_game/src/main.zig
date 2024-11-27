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

fn trimWhitespace(input: []const u8) []const u8 {
    return std.mem.trim(u8, input, " \n\t\r");
}

fn parseGame(input: []const u8, allocator: Allocator) !Game {
    const idx = std.mem.indexOf(u8, input, ":");
    const game_str: []const u8 = trimWhitespace(input[0..idx.?]);
    const draws_str: []const u8 = trimWhitespace(input[idx.? + 1 ..]);

    var game = Game.init(allocator);
    var draws_it = std.mem.tokenizeScalar(u8, draws_str, ';');
    while (draws_it.next()) |draw_str| {
        try game.draws.append(try parseDraw(draw_str));
    }

    game.id = try parseGameId(game_str);
    return game;
}

fn parseDraw(input: []const u8) !Draw {
    var draw: Draw = .{
        .red = 0,
        .green = 0,
        .blue = 0,
    };
    var it = std.mem.tokenizeScalar(u8, input, ',');
    while (it.next()) |num_color| {
        const nc = trimWhitespace(num_color);
        const idx = std.mem.indexOf(u8, nc, " ");
        const num_chars = nc[0..idx.?];
        const color = nc[idx.? + 1 ..];

        if (std.mem.eql(u8, color, "red")) {
            draw.red = try std.fmt.parseInt(usize, num_chars, 10);
        } else if (std.mem.eql(u8, color, "green")) {
            draw.green = try std.fmt.parseInt(usize, num_chars, 10);
        } else if (std.mem.eql(u8, color, "blue")) {
            draw.blue = try std.fmt.parseInt(usize, num_chars, 10);
        }
    }
    return draw;
}

fn parseGameId(input: []const u8) !usize {
    const idx = std.mem.indexOf(u8, input, " ");
    return std.fmt.parseInt(usize, input[idx.? + 1 ..], 10);
}

fn gameIsPossible(game: *const Game, bag: *const Draw) bool {
    for (game.draws.items) |*draw| {
        if (draw.red > bag.red or
            draw.green > bag.green or
            draw.blue > bag.blue)
        {
            return false;
        }
    }
    return true;
}

fn getSmallestPossibleBagForGame(game: *const Game) Draw {
    var bag = Draw{
        .red = 0,
        .green = 0,
        .blue = 0,
    };

    for (game.draws.items) |*draw| {
        if (draw.red > bag.red) {
            bag.red = draw.red;
        }
        if (draw.blue > bag.blue) {
            bag.blue = draw.blue;
        }
        if (draw.green > bag.green) {
            bag.green = draw.green;
        }
    }
    return bag;
}

fn getPower(bag: *const Draw) usize {
    return bag.red * bag.green * bag.blue;
}

pub fn main() !void {
    var file = try std.fs.cwd().openFile("input.txt", .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var buf: [1024]u8 = undefined;

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    const allocator = arena.allocator();

    const bag = Draw{
        .red = 12,
        .green = 13,
        .blue = 14,
    };

    var sum_possible_game_ids: usize = 0;
    var sum_of_power: usize = 0;
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        const game = try parseGame(line, allocator);
        defer game.deinit();

        if (gameIsPossible(&game, &bag)) {
            sum_possible_game_ids += game.id;
        }
        const smallest_bag = getSmallestPossibleBagForGame(&game);
        sum_of_power += getPower(&smallest_bag);
    }

    std.debug.print("Sum of possible game id's: {d}\n", .{sum_possible_game_ids});
    std.debug.print("Sum of all smallest bag's power: {d}\n", .{sum_of_power});
}

test "simple test" {
    const draw_str = "5 red, 6 blue, 9 green";
    const draw = try parseDraw(draw_str);
    try std.testing.expectEqual(draw.red, 5);
    try std.testing.expectEqual(draw.blue, 6);
    try std.testing.expectEqual(draw.green, 9);
}
