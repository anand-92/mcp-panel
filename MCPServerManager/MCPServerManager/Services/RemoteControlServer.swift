import Foundation
import NIOCore
import NIOPosix
import NIOHTTP1
import NIOWebSocket
import NIOExtras

/// WebSocket handler for remote control connections
final class WebSocketHandler: ChannelInboundHandler {
    typealias InboundIn = WebSocketFrame
    typealias OutboundOut = WebSocketFrame

    private let server: RemoteControlServer
    private var isAuthenticated = false

    init(server: RemoteControlServer) {
        self.server = server
    }

    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let frame = unwrapInboundIn(data)

        switch frame.opcode {
        case .text:
            var data = frame.unmaskedData
            let text = data.readString(length: data.readableBytes) ?? ""
            handleTextMessage(text, context: context)

        case .connectionClose:
            context.close(promise: nil)

        case .ping:
            // Respond with pong
            let pongFrame = WebSocketFrame(fin: true, opcode: .pong, data: frame.data)
            context.writeAndFlush(wrapOutboundOut(pongFrame), promise: nil)

        default:
            break
        }
    }

    private func handleTextMessage(_ text: String, context: ChannelHandlerContext) {
        guard let data = text.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            sendError("Invalid JSON", context: context)
            return
        }

        guard let type = json["type"] as? String else {
            sendError("Missing type field", context: context)
            return
        }

        switch type {
        case "auth":
            handleAuth(json, context: context)

        case "getServers":
            if isAuthenticated {
                handleGetServers(context: context)
            } else {
                sendError("Not authenticated", context: context)
            }

        case "toggleServer":
            if isAuthenticated {
                handleToggleServer(json, context: context)
            } else {
                sendError("Not authenticated", context: context)
            }

        default:
            sendError("Unknown message type", context: context)
        }
    }

    private func handleAuth(_ json: [String: Any], context: ChannelHandlerContext) {
        guard let token = json["token"] as? String else {
            sendError("Missing token", context: context)
            return
        }

        if server.validateToken(token) {
            isAuthenticated = true
            server.addConnection(context.channel)
            sendResponse(["type": "authSuccess", "message": "Authenticated"], context: context)
        } else {
            sendError("Invalid token", context: context)
            context.close(promise: nil)
        }
    }

    private func handleGetServers(context: ChannelHandlerContext) {
        Task { @MainActor in
            if let servers = server.onGetServers?() {
                let activeIndex = server.getActiveConfigIndex?() ?? 0
                let serverData = servers.map { server in
                    let enabled = server.inConfigs.indices.contains(activeIndex) ? server.inConfigs[activeIndex] : false
                    return [
                        "id": server.id.uuidString,
                        "name": server.name,
                        "enabled": enabled,
                        "summary": server.config.summary
                    ] as [String: Any]
                }

                sendResponse([
                    "type": "serverList",
                    "servers": serverData
                ], context: context)
            }
        }
    }

    private func handleToggleServer(_ json: [String: Any], context: ChannelHandlerContext) {
        guard let serverId = json["serverId"] as? String else {
            sendError("Missing serverId", context: context)
            return
        }

        Task { @MainActor in
            server.onToggleServer?(serverId)
            sendResponse([
                "type": "toggleSuccess",
                "serverId": serverId
            ], context: context)
        }
    }

    private func sendResponse(_ response: [String: Any], context: ChannelHandlerContext) {
        guard let data = try? JSONSerialization.data(withJSONObject: response),
              let json = String(data: data, encoding: .utf8) else {
            return
        }

        var buffer = context.channel.allocator.buffer(capacity: json.utf8.count)
        buffer.writeString(json)

        let frame = WebSocketFrame(fin: true, opcode: .text, data: buffer)
        context.writeAndFlush(wrapOutboundOut(frame), promise: nil)
    }

    private func sendError(_ message: String, context: ChannelHandlerContext) {
        sendResponse(["type": "error", "message": message], context: context)
    }
}

/// HTTP handler that upgrades to WebSocket or serves static content
final class HTTPHandler: ChannelInboundHandler {
    typealias InboundIn = HTTPServerRequestPart
    typealias OutboundOut = HTTPServerResponsePart

    private let server: RemoteControlServer
    private var requestHead: HTTPRequestHead?

    init(server: RemoteControlServer) {
        self.server = server
    }

    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let reqPart = unwrapInboundIn(data)

        switch reqPart {
        case .head(let head):
            requestHead = head

        case .end:
            if let head = requestHead {
                handleRequest(head: head, context: context)
            }

        default:
            break
        }
    }

    private func handleRequest(head: HTTPRequestHead, context: ChannelHandlerContext) {
        let path = head.uri.split(separator: "?").first.map(String.init) ?? head.uri

        switch path {
        case "/":
            serveHTML(context: context)

        case "/ws":
            // WebSocket upgrade is handled by the pipeline

            break

        default:
            send404(context: context)
        }
    }

    private func serveHTML(context: ChannelHandlerContext) {
        let html = server.webAppHTML

        var headers = HTTPHeaders()
        headers.add(name: "Content-Type", value: "text/html; charset=utf-8")
        headers.add(name: "Content-Length", value: "\(html.utf8.count)")

        let responseHead = HTTPResponseHead(
            version: .http1_1,
            status: .ok,
            headers: headers
        )

        context.write(wrapOutboundOut(.head(responseHead)), promise: nil)

        var buffer = context.channel.allocator.buffer(capacity: html.utf8.count)
        buffer.writeString(html)
        context.write(wrapOutboundOut(.body(.byteBuffer(buffer))), promise: nil)
        context.writeAndFlush(wrapOutboundOut(.end(nil)), promise: nil)
    }

    private func send404(context: ChannelHandlerContext) {
        let html = "<html><body><h1>404 Not Found</h1></body></html>"

        var headers = HTTPHeaders()
        headers.add(name: "Content-Type", value: "text/html")
        headers.add(name: "Content-Length", value: "\(html.utf8.count)")

        let responseHead = HTTPResponseHead(
            version: .http1_1,
            status: .notFound,
            headers: headers
        )

        context.write(wrapOutboundOut(.head(responseHead)), promise: nil)

        var buffer = context.channel.allocator.buffer(capacity: html.utf8.count)
        buffer.writeString(html)
        context.write(wrapOutboundOut(.body(.byteBuffer(buffer))), promise: nil)
        context.writeAndFlush(wrapOutboundOut(.end(nil)), promise: nil)
    }
}

/// Main remote control server
@MainActor
class RemoteControlServer: ObservableObject {
    @Published var isRunning = false
    @Published var session: RemoteControlSession?

    private var group: MultiThreadedEventLoopGroup?
    private var bootstrap: ServerBootstrap?
    private var channel: Channel?
    private var connections: [Channel] = []

    var onGetServers: (() -> [ServerModel])?
    var onToggleServer: ((String) -> Void)?
    var getActiveConfigIndex: (() -> Int)?

    let webAppHTML: String

    init() {
        // Initialize with web app HTML
        self.webAppHTML = RemoteControlServer.defaultWebAppHTML()
    }

    /// Starts the remote control server
    func start(port: Int = 8765) throws {
        guard !isRunning else { return }

        let ipAddress = getLocalIPAddress() ?? "127.0.0.1"
        session = RemoteControlSession(ipAddress: ipAddress, port: port)
        session?.isActive = true

        let group = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
        self.group = group

        let server = self

        let bootstrap = ServerBootstrap(group: group)
            .serverChannelOption(ChannelOptions.backlog, value: 256)
            .serverChannelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
            .childChannelInitializer { channel in
                let httpHandler = HTTPHandler(server: server)
                let config = NIOHTTPServerUpgradeConfiguration(
                    upgraders: [NIOWebSocketServerUpgrader(
                        shouldUpgrade: { _, _ in channel.eventLoop.makeSucceededFuture(HTTPHeaders()) },
                        upgradePipelineHandler: { channel, _ in
                            channel.pipeline.addHandler(WebSocketHandler(server: server))
                        }
                    )],
                    completionHandler: { _ in }
                )

                return channel.pipeline.configureHTTPServerPipeline(withServerUpgrade: config).flatMap {
                    channel.pipeline.addHandler(httpHandler)
                }
            }
            .childChannelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)

        self.bootstrap = bootstrap

        let channel = try bootstrap.bind(host: "0.0.0.0", port: port).wait()
        self.channel = channel

        isRunning = true

        print("✅ Remote Control Server started on \(ipAddress):\(port)")
    }

    /// Stops the remote control server
    func stop() {
        guard isRunning else { return }

        // Close all connections
        for connection in connections {
            connection.close(mode: .all, promise: nil)
        }
        connections.removeAll()

        // Close server channel
        try? channel?.close().wait()
        try? group?.syncShutdownGracefully()

        channel = nil
        group = nil
        bootstrap = nil
        session?.isActive = false
        isRunning = false

        print("🛑 Remote Control Server stopped")
    }

    func validateToken(_ token: String) -> Bool {
        return session?.validateToken(token) ?? false
    }

    func addConnection(_ channel: Channel) {
        connections.append(channel)
    }

    /// Broadcasts a message to all connected clients
    func broadcast(_ message: [String: Any]) {
        guard let data = try? JSONSerialization.data(withJSONObject: message),
              let json = String(data: data, encoding: .utf8) else {
            return
        }

        for connection in connections {
            var buffer = connection.allocator.buffer(capacity: json.utf8.count)
            buffer.writeString(json)
            let frame = WebSocketFrame(fin: true, opcode: .text, data: buffer)
            connection.writeAndFlush(frame, promise: nil)
        }
    }

    private func getLocalIPAddress() -> String? {
        var address: String?

        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0 else { return nil }
        guard let firstAddr = ifaddr else { return nil }

        for ifptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let interface = ifptr.pointee
            let addrFamily = interface.ifa_addr.pointee.sa_family

            if addrFamily == UInt8(AF_INET) {
                let name = String(cString: interface.ifa_name)
                if name == "en0" || name == "en1" {
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    getnameinfo(interface.ifa_addr,
                              socklen_t(interface.ifa_addr.pointee.sa_len),
                              &hostname,
                              socklen_t(hostname.count),
                              nil,
                              socklen_t(0),
                              NI_NUMERICHOST)
                    address = String(cString: hostname)
                }
            }
        }

        freeifaddrs(ifaddr)
        return address
    }

    static func defaultWebAppHTML() -> String {
        return """
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
            <title>MCP Control Panel</title>
            <style>
                * {
                    margin: 0;
                    padding: 0;
                    box-sizing: border-box;
                }

                body {
                    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
                    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                    min-height: 100vh;
                    padding: 20px;
                    color: white;
                }

                .container {
                    max-width: 600px;
                    margin: 0 auto;
                }

                h1 {
                    text-align: center;
                    margin-bottom: 10px;
                    font-size: 28px;
                    text-shadow: 0 2px 10px rgba(0,0,0,0.2);
                }

                .status {
                    text-align: center;
                    margin-bottom: 30px;
                    font-size: 14px;
                    opacity: 0.9;
                }

                .status.connected {
                    color: #4ade80;
                }

                .status.disconnected {
                    color: #fbbf24;
                }

                .server-list {
                    display: flex;
                    flex-direction: column;
                    gap: 12px;
                }

                .server-card {
                    background: rgba(255, 255, 255, 0.15);
                    backdrop-filter: blur(10px);
                    border-radius: 16px;
                    padding: 20px;
                    border: 1px solid rgba(255, 255, 255, 0.2);
                    box-shadow: 0 8px 32px rgba(0, 0, 0, 0.1);
                    transition: all 0.3s ease;
                }

                .server-card.enabled {
                    background: rgba(74, 222, 128, 0.2);
                    border-color: rgba(74, 222, 128, 0.3);
                }

                .server-header {
                    display: flex;
                    justify-content: space-between;
                    align-items: center;
                    margin-bottom: 8px;
                }

                .server-name {
                    font-weight: 600;
                    font-size: 18px;
                }

                .server-summary {
                    font-size: 14px;
                    opacity: 0.8;
                    line-height: 1.4;
                }

                .toggle-switch {
                    position: relative;
                    width: 56px;
                    height: 32px;
                    background: rgba(255, 255, 255, 0.3);
                    border-radius: 16px;
                    cursor: pointer;
                    transition: background 0.3s;
                    flex-shrink: 0;
                }

                .toggle-switch.enabled {
                    background: #4ade80;
                }

                .toggle-slider {
                    position: absolute;
                    top: 3px;
                    left: 3px;
                    width: 26px;
                    height: 26px;
                    background: white;
                    border-radius: 50%;
                    transition: transform 0.3s;
                    box-shadow: 0 2px 8px rgba(0, 0, 0, 0.2);
                }

                .toggle-switch.enabled .toggle-slider {
                    transform: translateX(24px);
                }

                .loading {
                    text-align: center;
                    padding: 40px;
                    font-size: 16px;
                }

                .error {
                    background: rgba(239, 68, 68, 0.2);
                    border: 1px solid rgba(239, 68, 68, 0.3);
                    border-radius: 12px;
                    padding: 16px;
                    margin-bottom: 20px;
                    text-align: center;
                }

                @keyframes pulse {
                    0%, 100% { opacity: 1; }
                    50% { opacity: 0.5; }
                }

                .pulse {
                    animation: pulse 2s ease-in-out infinite;
                }
            </style>
        </head>
        <body>
            <div class="container">
                <h1>🎛️ MCP Control Panel</h1>
                <div class="status disconnected" id="status">Connecting...</div>
                <div id="error" class="error" style="display: none;"></div>
                <div id="loading" class="loading">Loading servers...</div>
                <div id="serverList" class="server-list" style="display: none;"></div>
            </div>

            <script>
                const params = new URLSearchParams(window.location.search);
                const token = params.get('token');

                if (!token) {
                    showError('No authentication token provided');
                }

                const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
                const ws = new WebSocket(`${protocol}//${window.location.host}/ws`);

                let servers = [];

                ws.onopen = () => {
                    console.log('WebSocket connected');
                    ws.send(JSON.stringify({ type: 'auth', token: token }));
                };

                ws.onmessage = (event) => {
                    const msg = JSON.parse(event.data);
                    handleMessage(msg);
                };

                ws.onerror = (error) => {
                    console.error('WebSocket error:', error);
                    showError('Connection error');
                };

                ws.onclose = () => {
                    document.getElementById('status').textContent = 'Disconnected';
                    document.getElementById('status').className = 'status disconnected';
                };

                function handleMessage(msg) {
                    switch (msg.type) {
                        case 'authSuccess':
                            document.getElementById('status').textContent = 'Connected';
                            document.getElementById('status').className = 'status connected';
                            ws.send(JSON.stringify({ type: 'getServers' }));
                            break;

                        case 'serverList':
                            servers = msg.servers;
                            renderServers();
                            break;

                        case 'toggleSuccess':
                            // Update local state
                            const server = servers.find(s => s.id === msg.serverId);
                            if (server) {
                                server.enabled = !server.enabled;
                                renderServers();
                            }
                            break;

                        case 'serverUpdate':
                            // Real-time update from server
                            ws.send(JSON.stringify({ type: 'getServers' }));
                            break;

                        case 'error':
                            showError(msg.message);
                            break;
                    }
                }

                function renderServers() {
                    document.getElementById('loading').style.display = 'none';
                    document.getElementById('serverList').style.display = 'flex';

                    const listEl = document.getElementById('serverList');
                    listEl.innerHTML = '';

                    servers.forEach(server => {
                        const card = document.createElement('div');
                        card.className = `server-card ${server.enabled ? 'enabled' : ''}`;

                        card.innerHTML = `
                            <div class="server-header">
                                <div class="server-name">${escapeHtml(server.name)}</div>
                                <div class="toggle-switch ${server.enabled ? 'enabled' : ''}" data-id="${server.id}">
                                    <div class="toggle-slider"></div>
                                </div>
                            </div>
                            <div class="server-summary">${escapeHtml(server.summary || 'No description')}</div>
                        `;

                        const toggle = card.querySelector('.toggle-switch');
                        toggle.addEventListener('click', () => toggleServer(server.id));

                        listEl.appendChild(card);
                    });
                }

                function toggleServer(serverId) {
                    ws.send(JSON.stringify({
                        type: 'toggleServer',
                        serverId: serverId
                    }));
                }

                function showError(message) {
                    const errorEl = document.getElementById('error');
                    errorEl.textContent = message;
                    errorEl.style.display = 'block';
                }

                function escapeHtml(text) {
                    const div = document.createElement('div');
                    div.textContent = text;
                    return div.innerHTML;
                }
            </script>
        </body>
        </html>
        """
    }
}
