//! By convention, root.zig is the root source file when making a library.
const std = @import("std");

const m = @cImport(@cInclude("magic.h"));

/// A simple Zig wrapper around libmagic
///
/// Example usage:
/// ```zig
/// const magic = @import("path/to/zexplorer/src/root.zig");
///
/// const allocator = std.heap.page_allocator;
/// var magic = try magic.Magic.init();
/// defer magic.deinit();
/// try magic.load();
///
/// const file_type = try magic.from_path(allocator, "somefile.txt");
/// std.debug.print("File type: {s}\n", .{file_type});
/// }
/// ```
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

    /// Get the file type from a file path
    pub fn from_path(self: *Magic, allocator: std.mem.Allocator, path: []const u8) ![]const u8 {
        const path_z = try allocator.dupeZ(u8, path);
        defer allocator.free(path_z);

        const res = m.magic_file(self.cookie, path_z.ptr);
        if (res == null) {
            return error.MagicFileFailed;
        }
        return std.mem.span(res);
    }

    /// Get the file type from a memory buffer
    pub fn from_buffer(self: *Magic, buffer: []const u8) ![]const u8 {
        const res = m.magic_buffer(self.cookie, buffer.ptr, buffer.len);
        if (res == null) {
            return error.MagicBufferFailed;
        }
        return std.mem.span(res);
    }

    /// Get the file type from a file descriptor
    pub fn from_handle(self: *Magic, handle: i32) ![]const u8 {
        const res = m.magic_descriptor(self.cookie, handle);
        if (res == null) {
            return error.MagicFdFailed;
        }
        return std.mem.span(res);
    }
};
