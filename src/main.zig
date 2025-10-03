const std = @import("std");
const lib = @import("magic_zig");

const m = lib.Magic;

test "file buffer" {
    const allocator = std.testing.allocator;
    var magic = try m.init();
    defer magic.deinit();

    const file_contents = try std.fs.cwd().readFileAlloc(allocator, "src/main.zig", 1024 * 1024);
    defer allocator.free(file_contents);
    try magic.load();
    const mime = try magic.from_buffer(file_contents);
    try std.testing.expectEqualSlices(u8, "text/x-c", mime);
}

test "streamed buffer" {
    const allocator = std.testing.allocator;
    var magic = try m.init();
    defer magic.deinit();

    var file = try std.fs.cwd().openFile("src/main.zig", .{ .mode = .read_only });
    defer file.close();

    var read_buf: [1024]u8 = undefined;
    var file_reader = file.reader(&read_buf);
    const reader = &file_reader.interface;

    var line = std.Io.Writer.Allocating.init(allocator);
    defer line.deinit();

    var file_as_list: std.ArrayList(u8) = .empty;

    // read line by line
    while (true) {
        _ = reader.streamDelimiter(&line.writer, '\n') catch |err| {
            if (err == error.EndOfStream) break else return err;
        };
        reader.toss(1); // consume the delimiter
        try file_as_list.appendSlice(allocator, line.written());
        line.clearRetainingCapacity();
    }

    try magic.load();
    const streamed_content = try file_as_list.toOwnedSlice(allocator);
    defer allocator.free(streamed_content);

    const mime = try magic.from_buffer(streamed_content);
    try std.testing.expectEqualSlices(u8, "text/x-c", mime);
}

test "file descriptor" {
    var magic = try m.init();
    defer magic.deinit();

    var file = try std.fs.cwd().openFile("src/main.zig", .{ .mode = .read_only });
    defer file.close();

    try magic.load();
    const mime = try magic.from_handle(file.handle);
    try std.testing.expectEqualSlices(u8, "text/x-c", mime);
}

test "from paths" {
    const allocator = std.testing.allocator;
    var magic = try m.init();
    defer magic.deinit();

    try magic.load();

    const paths = [_][]const u8{
        "src/tests/icons8-globe-24.png",
        "src/tests/t.png",
        "src/tests/test.txt",
        "src/tests/eggs-2-svgrepo-com.svg",
        "src/tests/ex_module.ex",
        "src/tests/test.json",
        "src/tests/robots.txt.gz",
        "README.md",
        "src/tests/htmz.sql3",
        "src/tests/simple.js",
    };

    const expected_mimes = [_][]const u8{
        "image/png",
        "text/plain",
        "text/plain",
        "image/svg+xml",
        "text/plain",
        "application/json",
        "application/gzip",
        "text/plain",
        "application/vnd.sqlite3",
        "application/javascript",
    };

    for (paths, 0..) |path, i| {
        const mime = try magic.from_path(allocator, path);

        try std.testing.expectEqualSlices(u8, expected_mimes[i], mime);
    }
}

// pub fn main() !void {
//     // 1 - print to stdout
//     var stdout_buffer: [1024]u8 = undefined;
//     var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
//     const stdout = &stdout_writer.interface;

//     // 2 - allocator
//     var gpa = std.heap.GeneralPurposeAllocator(.{ .safety = true }){};
//     const allocator = gpa.allocator();
//     defer {
//         std.debug.assert(!gpa.detectLeaks());
//         _ = gpa.deinit();
//     }

//     // 3 - read file
//     // Non-streaming approach (reads entire file at once):
//     // const file_contents = try std.fs.cwd().readFileAlloc(allocator, "src/main.zig", 1024 * 1024);
//     // defer allocator.free(file_contents);

//     // Streaming approach with std.Io (Zig 0.15.1):
//     var file = try std.fs.cwd().openFile("src/main.zig", .{ .mode = .read_only });
//     defer file.close();

//     var read_buf: [1024]u8 = undefined;
//     var file_reader = file.reader(&read_buf);
//     const reader = &file_reader.interface;

//     var line = std.Io.Writer.Allocating.init(allocator);
//     defer line.deinit();

//     var file_as_list: std.ArrayList(u8) = .empty;

//     // read line by line
//     while (true) {
//         _ = reader.streamDelimiter(&line.writer, '\n') catch |err| {
//             if (err == error.EndOfStream) break else return err;
//         };
//         reader.toss(1); // consume the delimiter
//         try file_as_list.appendSlice(allocator, line.written());
//         line.clearRetainingCapacity();
//     }

//     var magic = try m.init();
//     defer magic.deinit();

//     magic.load() catch {
//         try stdout.print("Error loading magic database: {s}\n", .{magic.merror()});

//         return error.MagicLoadFailed;
//     };

//     const streamed_content = try file_as_list.toOwnedSlice(allocator);
//     defer allocator.free(streamed_content);

//     const mime_of_stream = try magic.from_buffer(streamed_content);
//     try stdout.print("{s}\n", .{mime_of_stream});

//     const mime_from_descriptor = try magic.from_handle(file.handle);
//     try stdout.print("{s}\n", .{mime_from_descriptor});

//     const paths = [_][]const u8{
//         "src/icons8-globe-24.png",
//         "src/t.png",
//     };

//     for (paths) |path| {
//         const mime_slice = try magic.from_path(allocator, path);

//         try stdout.print("\nFile: {s}, MIME Type: {s}\n", .{ path, mime_slice });
//     }

//     try stdout.flush();
// }
