pub const Config = struct {
    pub const HOST = [4]u8{ 0, 0, 0, 0 };
    pub const PORT = 80;
    pub const MAX_REQUEST_SIZE = 1024;
    pub const RESPONSE =
        "HTTP/1.1 200 OK\r\n" ++
        "Content-Length: 46\r\n" ++
        "Content-Type: text/plain\r\n" ++
        "Connection: Closed\r\n" ++
        "\r\n" ++
        "halcyon|nouveau\n\nReach Heaven Through PrivEsc\n";
};
