const std = @import("std");

fn is_numeric(c: u8) bool {
    return c >= 0x30 and c < 0x3a;
}

const CharPredicate = *const fn (c: u8) bool;

fn find_first_of(s: []const u8, pred: CharPredicate) ?*const u8 {
    var char_ptr: ?*const u8 = null;
    for (s) |*c| {
        if (pred(c.*)) {
            char_ptr = c;
            break;
        }
    }
    return char_ptr;
}

fn find_last_of(s: []const u8, pred: CharPredicate) ?*const u8 {
    var char_ptr: ?*const u8 = null;
    for (0..s.len) |i| {
        const idx: usize = s.len - i - 1;
        const c: *const u8 = &s[idx];
        if (pred(c.*)) {
            char_ptr = c;
            break;
        }
    }
    return char_ptr;
}

fn numeric_char_to_i64(c: u8) i64 {
    return @as(i64, c - 0x30);
}

fn to_i64(s: []const u8) i64 {
    var total: i64 = 0;
    for (s) |c| {
        total = total * 10 + numeric_char_to_i64(c);
    }
    return total;
}

fn first_and_last_number_chars(s: []const u8) i64 {
    const numeric_chars = try extract_first_and_last_numbers(s);
    var total: i64 = 0;
    for (numeric_chars) |c| {
        total = total * 10 + to_i64(c);
    }
    return total;
}

const ParseError = error{NumericNotFound};

fn extract_first_and_last_numbers(input: []const u8) ParseError![2]u8 {
    const c1 = find_first_of(input, is_numeric);
    if (c1 == null) {
        return ParseError.NumericNotFound;
    }

    const c2 = find_last_of(input, is_numeric);
    if (c2 == null) {
        return ParseError.NumericNotFound;
    }

    return .{ c1.?.*, c1.?.* };
}

fn extract_first_and_last_spelled_or_char_num(input: []const u8) ParseError![2]u8 {
    const first_digit = first_number_char_or_spelled_number(input);
    const last_digit = last_number_char_or_spelled_number(input);

    if (first_digit == null) {
        return ParseError.NumericNotFound;
    }
    if (last_digit == null) {
        return ParseError.NumericNotFound;
    }
    return .{ first_digit.?, last_digit.? };
}

fn first_number_char_or_spelled_number(input: []const u8) ?u8 {
    const spelled_numbers: [10][]const u8 = .{ "zero", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine" };

    const num_chars: [10][]const u8 = .{ "0", "1", "2", "3", "4", "5", "6", "7", "8", "9" };

    var i_min: ?usize = null;
    var num: u8 = undefined;
    for (spelled_numbers, num_chars, 0..) |spelled_num, num_char, i| {
        var maybe_idx = std.mem.indexOf(u8, input, spelled_num);
        if (maybe_idx) |idx| {
            if (i_min == null or idx < i_min.?) {
                num = @truncate(i);
                i_min = idx;
            }
        }

        maybe_idx = std.mem.indexOf(u8, input, num_char);
        if (maybe_idx) |idx| {
            if (i_min == null or idx < i_min.?) {
                num = @truncate(i);
                i_min = idx;
            }
        }
    }

    if (i_min == null) {
        return null;
    } else {
        return num;
    }
}

fn last_number_char_or_spelled_number(input: []const u8) ?u8 {
    const spelled_numbers: [10][]const u8 = .{ "zero", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine" };
    const num_chars: [10][]const u8 = .{ "0", "1", "2", "3", "4", "5", "6", "7", "8", "9" };

    var i_max: ?usize = null;
    var num: u8 = undefined;
    for (spelled_numbers, num_chars, 0..) |spelled_num, num_char, i| {
        var maybe_idx = std.mem.lastIndexOf(u8, input, spelled_num);
        if (maybe_idx) |idx| {
            if (i_max == null or idx > i_max.?) {
                num = @truncate(i);
                i_max = idx;
            }
        }

        maybe_idx = std.mem.lastIndexOf(u8, input, num_char);
        if (maybe_idx) |idx| {
            if (i_max == null or idx > i_max.?) {
                num = @truncate(i);
                i_max = idx;
            }
        }
    }

    if (i_max == null) {
        return null;
    } else {
        return num;
    }
}

pub fn main() !void {
    const my_str = "haha1kk";
    const first_number_it = find_first_of(my_str, is_numeric);
    try std.testing.expect(first_number_it != null);
    const ptr_to_one: *const u8 = &my_str[4];
    try std.testing.expectEqual(first_number_it.?, ptr_to_one);

    var file = try std.fs.cwd().openFile("input.txt", .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var buf: [1024]u8 = undefined;

    var total: i64 = 0;
    var total_with_spelled: i64 = 0;
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        const num_chars = try extract_first_and_last_numbers(line);
        total += to_i64(&num_chars);

        const nums = try extract_first_and_last_spelled_or_char_num(line);
        total_with_spelled += @as(i64, nums[0] * 10 + nums[1]);

        std.debug.print("{s} {d} {d}\n", .{ line, total, total_with_spelled });
    }
}

test "first spelled numbers or char num" {
    const my_str = "hahahone2";
    const maybe_val = first_number_char_or_spelled_number(my_str);
    try std.testing.expect(maybe_val != null);
    try std.testing.expectEqual(1, maybe_val);
}

test "last spelled numbers or char num" {
    const my_str = "hahahone2";
    const maybe_val = last_number_char_or_spelled_number(my_str);
    try std.testing.expect(maybe_val != null);
    try std.testing.expectEqual(2, maybe_val);
}

test "numeric str to i64" {
    const s = "123";
    try std.testing.expectEqual(123, to_i64(s));
}

test "is numeric test" {
    try std.testing.expect(is_numeric('0'));
    try std.testing.expect(is_numeric('1'));
    try std.testing.expect(is_numeric('2'));
    try std.testing.expect(is_numeric('3'));
    try std.testing.expect(is_numeric('4'));
    try std.testing.expect(is_numeric('5'));
    try std.testing.expect(is_numeric('6'));
    try std.testing.expect(is_numeric('7'));
    try std.testing.expect(is_numeric('8'));
    try std.testing.expect(is_numeric('9'));
    try std.testing.expect(!is_numeric('a'));
}

test "find first of test" {
    const my_str = "haha1kk";
    const first_number_it = find_first_of(my_str, is_numeric);
    try std.testing.expect(first_number_it != null);
    const ptr_to_one: *const u8 = &my_str[4];
    try std.testing.expectEqual(first_number_it.?, ptr_to_one);
}

test "find last of test" {
    const my_str = "haha1to2tff";
    const last_number_it = find_last_of(my_str, is_numeric);
    try std.testing.expect(last_number_it != null);
    const ptr_to_2: *const u8 = &my_str[7];
    try std.testing.expectEqual(last_number_it.?, ptr_to_2);
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
