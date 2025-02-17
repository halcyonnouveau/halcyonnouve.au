const std = @import("std");
const config = @import("config.zig");
const builtin = @import("builtin");
const net = @import("std").net;

const Config = config.Config;
const Connection = std.net.Server.Connection;
const stdout = std.io.getStdOut().writer();

pub const Socket = struct {
    _address: std.net.Address,
    _stream: std.net.Stream,

    pub fn init() !Socket {
        const addr = net.Address.initIp4(Config.HOST, Config.PORT);
        const socket = try std.posix.socket(addr.any.family, std.posix.SOCK.STREAM | std.posix.SOCK.NONBLOCK, std.posix.IPPROTO.TCP);
        const stream = net.Stream{ .handle = socket };
        return Socket{ ._address = addr, ._stream = stream };
    }
};

fn handle_connection(connection: Connection) !void {
    defer connection.stream.close();

    var buffer: [Config.MAX_REQUEST_SIZE]u8 = undefined;
    const bytes_read = try connection.stream.read(&buffer);
    if (bytes_read == 0) return;

    _ = try connection.stream.write(Config.RESPONSE);
}

fn worker(server: *std.net.Server) !void {
    while (true) {
        const connection = server.accept() catch |err| {
            if (err == error.WouldBlock) continue;
            try stdout.print("Error accepting connection: {}\n", .{err});
            continue;
        };

        try handle_connection(connection);
    }
}

pub fn main() !void {
    const socket = try Socket.init();
    try stdout.print("Server starting at http://0.0.0.0:{d}\n", .{Config.PORT});

    var server = try socket._address.listen(.{
        .kernel_backlog = 128,
        .reuse_address = true,
    });
    defer server.deinit();

    const thread_count = try std.Thread.getCpuCount();
    const worker_count = @min(thread_count - 1, 15); // Leave one core for main thread

    try stdout.print("Starting {d} worker threads\n", .{worker_count});

    var threads = try std.ArrayList(std.Thread).initCapacity(std.heap.page_allocator, worker_count);
    defer threads.deinit();

    for (0..worker_count) |_| {
        const thread = try std.Thread.spawn(.{}, worker, .{&server});
        try threads.append(thread);
    }

    try worker(&server);
}
