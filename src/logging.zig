const std = @import("std");

pub const logger = std.log.scoped(.main);

pub var runtime_log_level: std.log.Level = .warn;

pub fn logRuntime(
    comptime level: std.log.Level,
    comptime scope: @EnumLiteral(),
    comptime format: []const u8,
    args: anytype,
) void {
    if (@intFromEnum(level) <= @intFromEnum(runtime_log_level)) {
        std.log.defaultLog(level, scope, format, args);
    }
}
