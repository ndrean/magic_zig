//! By convention, root.zig is the root source file when making a library.
const std = @import("std");
const m = @cImport(@cInclude("magic.h"));

pub fn bufferedPrint() !void {
    // Stdout is for the actual output of your application, for example if you
    // are implementing gzip, then only the compressed bytes should be sent to
    // stdout, not any debugging messages.
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    try stdout.print("\n", .{});

    try stdout.flush(); // Don't forget to flush!
}

pub const Magic = struct {
    cookie: m.magic_t,

    pub fn init() !Magic {
        const cookie = m.magic_open(m.MAGIC_MIME_TYPE) orelse return error.MagicOpenFailed;
        return Magic{ .cookie = cookie };
    }

    pub fn deinit(self: *Magic) void {
        m.magic_close(self.cookie);
    }

    pub fn load(self: *Magic) !void {
        if (m.magic_load(self.cookie, null) != 0) {
            return error.MagicLoadFailed;
        }
    }

    pub fn merror(self: *Magic) []const u8 {
        const err = std.mem.span(m.magic_error(self.cookie));
        return err;
    }

    pub fn from_path(self: *Magic, allocator: std.mem.Allocator, path: []const u8) ![]const u8 {
        const path_z = try allocator.dupeZ(u8, path);
        defer allocator.free(path_z);

        const res = m.magic_file(self.cookie, path_z.ptr);
        if (res == null) {
            return error.MagicFileFailed;
        }
        return std.mem.span(res);
    }

    pub fn from_buffer(self: *Magic, buffer: []const u8) ![]const u8 {
        const res = m.magic_buffer(self.cookie, buffer.ptr, buffer.len);
        if (res == null) {
            return error.MagicBufferFailed;
        }
        return std.mem.span(res);
    }

    pub fn from_handle(self: *Magic, handle: i32) ![]const u8 {
        const res = m.magic_descriptor(self.cookie, handle);
        if (res == null) {
            return error.MagicFdFailed;
        }
        return std.mem.span(res);
    }
};
