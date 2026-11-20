import os
import sys
import struct
import fcntl
import termios
import pty
import socket
import signal
import asyncio
import threading
from pathlib import Path
import streamlit as st
import streamlit.components.v1 as components

APP_DIR = Path(__file__).parent.resolve()
STATIC_DIR = APP_DIR / "static"
BIN_PATH = APP_DIR / "flowers"
WS_PORT = 8766
SYNC_END = b"\x1b[?2026l"

if BIN_PATH.exists():
    try:
        BIN_PATH.chmod(0o755)
    except Exception:
        pass

XTERM_CSS = (STATIC_DIR / "xterm.css").read_text(encoding="utf-8") if (STATIC_DIR / "xterm.css").exists() else ""
XTERM_JS = (STATIC_DIR / "xterm.js").read_text(encoding="utf-8") if (STATIC_DIR / "xterm.js").exists() else ""


class FrameReader:
    def __init__(self, master_fd: int):
        self.master_fd = master_fd
        self.buf = bytearray()

    def read_next_frame(self) -> bytes:
        while True:
            idx = self.buf.find(SYNC_END)
            if idx != -1:
                end_pos = idx + len(SYNC_END)
                frame = bytes(self.buf[:end_pos])
                del self.buf[:end_pos]
                while True:
                    next_idx = self.buf.find(SYNC_END)
                    if next_idx == -1:
                        break
                    next_end = next_idx + len(SYNC_END)
                    frame = bytes(self.buf[:next_end])
                    del self.buf[:next_end]
                return frame
            try:
                chunk = os.read(self.master_fd, 65536)
            except OSError:
                return b""
            if not chunk:
                return b""
            self.buf.extend(chunk)


def spawn_flowers_pty():
    master, slave = pty.openpty()
    winsize = struct.pack('HHHH', 52, 161, 0, 0)
    fcntl.ioctl(slave, termios.TIOCSWINSZ, winsize)

    pid = os.fork()
    if pid == 0:
        os.close(master)
        os.dup2(slave, 0)
        os.dup2(slave, 1)
        os.dup2(slave, 2)
        os.close(slave)
        os.chdir(str(APP_DIR))
        os.execl("./flowers", "./flowers")
        os._exit(1)

    os.close(slave)
    return master, pid


def cleanup_pty(master: int, pid: int):
    try:
        os.kill(pid, signal.SIGKILL)
        os.waitpid(pid, 0)
    except Exception:
        pass
    try:
        os.close(master)
    except Exception:
        pass


def register_primary_terminal_routes():
    import gc
    from streamlit import config
    from streamlit.url_util import make_url_path

    base_url = config.get_option("server.baseUrlPath") or ""
    route_paths = list({
        "/_stcore/terminal_stream",
        "/_terminal_stream",
        make_url_path(base_url, "_stcore/terminal_stream"),
        make_url_path(base_url, "_terminal_stream"),
    })

    try:
        from starlette.applications import Starlette
        from starlette.routing import WebSocketRoute

        app = None
        for obj in gc.get_objects():
            if isinstance(obj, Starlette):
                app = obj
                break

        if not app:
            for frame in sys._current_frames().values():
                curr = frame
                while curr:
                    for v in list(curr.f_locals.values()):
                        if isinstance(v, Starlette):
                            app = v
                            break
                        if hasattr(v, "_starlette_server") and getattr(v, "_starlette_server"):
                            srv = getattr(v, "_starlette_server")
                            if hasattr(srv, "_server") and srv._server and hasattr(srv._server, "config"):
                                app = srv._server.config.app
                                break
                    if app:
                        break
                    curr = curr.f_back
                if app:
                    break

        if app:
            app.routes[:] = [r for r in app.routes if getattr(r, "path", None) not in route_paths]

            async def starlette_ws(websocket):
                await websocket.accept()
                master, pid = spawn_flowers_pty()
                loop = asyncio.get_running_loop()
                frame_reader = FrameReader(master)
                ack_event = asyncio.Event()
                ack_event.set()

                async def reader():
                    try:
                        while True:
                            try:
                                await asyncio.wait_for(ack_event.wait(), timeout=0.25)
                            except asyncio.TimeoutError:
                                pass
                            ack_event.clear()

                            frame = await loop.run_in_executor(None, frame_reader.read_next_frame)
                            if not frame:
                                break
                            await websocket.send_bytes(frame)
                    except Exception:
                        pass

                async def writer():
                    try:
                        while True:
                            msg = await websocket.receive()
                            if msg.get("type") == "websocket.disconnect":
                                break
                            text = msg.get("text", "")
                            b = msg.get("bytes", b"")
                            if text == "ack" or b == b"ack":
                                ack_event.set()
                            else:
                                if text:
                                    os.write(master, text.encode("utf-8"))
                                elif b:
                                    os.write(master, b)
                    except Exception:
                        pass

                rtask = asyncio.create_task(reader())
                wtask = asyncio.create_task(writer())
                await asyncio.wait([rtask, wtask], return_when=asyncio.FIRST_COMPLETED)
                rtask.cancel()
                wtask.cancel()
                cleanup_pty(master, pid)

            for rp in route_paths:
                app.routes.insert(0, WebSocketRoute(rp, starlette_ws))
            return True
    except Exception:
        pass

    try:
        import tornado.web
        import tornado.websocket

        tornado_app = None
        for obj in gc.get_objects():
            if isinstance(obj, tornado.web.Application):
                tornado_app = obj
                break

        if tornado_app:
            class TornadoPtyHandler(tornado.websocket.WebSocketHandler):
                def check_origin(self, origin):
                    return True

                def open(self):
                    self.master, self.pid = spawn_flowers_pty()
                    self.frame_reader = FrameReader(self.master)
                    self.running = True
                    self.loop = asyncio.get_event_loop()
                    self.ack_event = asyncio.Event()
                    self.ack_event.set()
                    self.rtask = asyncio.ensure_future(self.read_loop())

                async def read_loop(self):
                    try:
                        while self.running:
                            try:
                                await asyncio.wait_for(self.ack_event.wait(), timeout=0.25)
                            except asyncio.TimeoutError:
                                pass
                            self.ack_event.clear()

                            frame = await self.loop.run_in_executor(None, self.frame_reader.read_next_frame)
                            if not frame or not self.running:
                                break
                            await self.write_message(frame, binary=True)
                    except Exception:
                        pass

                def on_message(self, message):
                    try:
                        if message == "ack" or message == b"ack":
                            self.ack_event.set()
                        elif isinstance(message, str):
                            os.write(self.master, message.encode("utf-8"))
                        elif isinstance(message, bytes):
                            os.write(self.master, message)
                    except Exception:
                        pass

                def on_close(self):
                    self.running = False
                    if hasattr(self, "rtask"):
                        self.rtask.cancel()
                    if hasattr(self, "master") and hasattr(self, "pid"):
                        cleanup_pty(self.master, self.pid)

            if not getattr(tornado_app, "_pty_route_registered", False):
                tornado_app.add_handlers(r".*", [
                    (r".*/_stcore/terminal_stream", TornadoPtyHandler),
                    (r".*/_terminal_stream", TornadoPtyHandler),
                ])
                tornado_app._pty_route_registered = True
            return True
    except Exception:
        pass

    return False


async def _fallback_ws_handler(websocket):
    master, pid = spawn_flowers_pty()
    loop = asyncio.get_running_loop()
    frame_reader = FrameReader(master)
    ack_event = asyncio.Event()
    ack_event.set()

    async def reader():
        try:
            while True:
                try:
                    await asyncio.wait_for(ack_event.wait(), timeout=0.25)
                except asyncio.TimeoutError:
                    pass
                ack_event.clear()

                frame = await loop.run_in_executor(None, frame_reader.read_next_frame)
                if not frame:
                    break
                await websocket.send(frame)
        except Exception:
            pass

    async def writer():
        try:
            async for msg in websocket:
                if msg == "ack" or msg == b"ack":
                    ack_event.set()
                elif isinstance(msg, str):
                    os.write(master, msg.encode("utf-8"))
                elif isinstance(msg, bytes):
                    os.write(master, msg)
        except Exception:
            pass

    rtask = asyncio.create_task(reader())
    wtask = asyncio.create_task(writer())
    await asyncio.wait([rtask, wtask], return_when=asyncio.FIRST_COMPLETED)
    rtask.cancel()
    wtask.cancel()
    cleanup_pty(master, pid)


sys._active_pty_ws_handler = _fallback_ws_handler


def is_port_in_use(port: int) -> bool:
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        return s.connect_ex(('127.0.0.1', port)) == 0


def start_background_pty_server():
    if is_port_in_use(WS_PORT):
        return

    def run_loop():
        loop = asyncio.new_event_loop()
        asyncio.set_event_loop(loop)
        from websockets.asyncio.server import serve

        async def delegating_handler(websocket):
            handler_fn = getattr(sys, "_active_pty_ws_handler", _fallback_ws_handler)
            await handler_fn(websocket)

        async def main():
            server = await serve(delegating_handler, None, WS_PORT)
            await server.serve_forever()

        try:
            loop.run_until_complete(main())
        except Exception:
            pass

    thread = threading.Thread(target=run_loop, daemon=True)
    thread.start()


register_primary_terminal_routes()
start_background_pty_server()

st.set_page_config(
    page_title="flowers.asm",
    page_icon="🥀",
    layout="wide",
    initial_sidebar_state="collapsed"
)

st.markdown("""
<style>
    header[data-testid="stHeader"] { display: none !important; }
    [data-testid="stSidebar"] { display: none !important; }
    [data-testid="stSidebarCollapsedControl"] { display: none !important; }
    footer { display: none !important; }
    #MainMenu { display: none !important; }
    .stDeployButton { display: none !important; }
    div[data-testid="stToolbar"] { display: none !important; }
    div[data-testid="stDecoration"] { display: none !important; }
    
    .stApp {
        background-color: #07080c !important;
        overflow: hidden !important;
    }
    
    .block-container {
        padding: 0 !important;
        margin: 0 !important;
        max-width: 100vw !important;
        height: 100vh !important;
    }
    
    iframe {
        border: none !important;
        width: 100vw !important;
        height: 100vh !important;
    }
</style>
""", unsafe_allow_html=True)

TERMINAL_HTML = f"""
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>flowers.asm</title>
    <style>
        {XTERM_CSS}
        
        * {{
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }}
        html, body {{
            width: 100%;
            height: 100%;
            background-color: #07080c;
            display: flex;
            align-items: center;
            justify-content: center;
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
            overflow: hidden;
            user-select: none;
        }}
        .window {{
            width: fit-content;
            height: fit-content;
            background: #090a0f;
            border-radius: 12px;
            border: 1px solid #1e2230;
            box-shadow: 0 25px 60px rgba(0, 0, 0, 0.8), 0 0 35px rgba(129, 140, 248, 0.1);
            display: inline-flex;
            flex-direction: column;
            overflow: hidden;
        }}
        .titlebar {{
            height: 38px;
            background: #11131a;
            border-bottom: 1px solid #1a1e2b;
            display: flex;
            align-items: center;
            padding: 0 14px;
            position: relative;
            flex-shrink: 0;
            width: 100%;
        }}
        .dots {{
            display: flex;
            gap: 7px;
        }}
        .dot {{
            width: 11px;
            height: 11px;
            border-radius: 50%;
        }}
        .dot.red {{ background: #ff5f56; }}
        .dot.yellow {{ background: #ffbd2e; }}
        .dot.green {{ background: #27c93f; }}
        .title {{
            position: absolute;
            left: 50%;
            transform: translateX(-50%);
            color: #8b949e;
            font-size: 12px;
            font-family: monospace;
            letter-spacing: 0.5px;
            display: flex;
            align-items: center;
            gap: 8px;
            white-space: nowrap;
        }}
        .status-badge {{
            font-size: 10px;
            padding: 2px 6px;
            border-radius: 4px;
            background: #1c2333;
            color: #60a5fa;
            border: 1px solid #2e3852;
        }}
        .status-badge.live {{
            color: #34d399;
            border-color: #065f46;
        }}
        .status-badge.err {{
            color: #f87171;
            border-color: #7f1d1d;
        }}
        .terminal-wrapper {{
            padding: 0;
            margin: 0;
            background: #090a0f;
            overflow: hidden;
            display: block;
            width: fit-content;
            height: fit-content;
        }}
        #terminal {{
            display: block;
            width: fit-content;
            height: fit-content;
        }}
        .xterm {{
            padding: 0 !important;
        }}
        .xterm-viewport {{
            overflow-y: hidden !important;
        }}
        .xterm-screen {{
            margin: 0 !important;
            padding: 0 !important;
        }}
    </style>
</head>
<body>

<div class="window" id="win">
    <div class="titlebar">
        <div class="dots">
            <div class="dot red"></div>
            <div class="dot yellow"></div>
            <div class="dot green"></div>
        </div>
        <div class="title">
            <span>flowers.asm (x86-64 NASM native raymarcher)</span>
            <span class="status-badge" id="status">INIT</span>
        </div>
    </div>
    
    <div class="terminal-wrapper" onclick="focusTerm()">
        <div id="terminal"></div>
    </div>
</div>

<script>
{XTERM_JS}
</script>

<script>
    const statusEl = document.getElementById('status');
    const term = new Terminal({{
        cols: 160,
        rows: 51,
        cursorBlink: false,
        fontFamily: '"JetBrains Mono", "Cascadia Code", "Fira Code", monospace',
        fontSize: 12,
        lineHeight: 1.0,
        letterSpacing: 0,
        theme: {{
            background: '#090a0f',
            foreground: '#e5e7eb'
        }}
    }});

    term.open(document.getElementById('terminal'));

    function snapWindowToTerminal() {{
        const screen = document.querySelector('.xterm-screen');
        const win = document.getElementById('win');
        if (screen && win) {{
            const w = screen.offsetWidth;
            const h = screen.offsetHeight;
            if (w > 0 && h > 0) {{
                win.style.width = (w + 2) + 'px';
                win.style.height = (h + 38 + 2) + 'px';
            }}
        }}
    }}

    function focusTerm() {{
        term.focus();
    }}
    focusTerm();

    let loc = window.location;
    try {{
        if (window.parent && window.parent.location && window.parent.location.host) {{
            loc = window.parent.location;
        }}
    }} catch (e) {{}}

    const proto = (loc.protocol === 'https:') ? 'wss:' : 'ws:';
    const basePath = (loc.pathname || '').replace(/\\/+$/, '');
    const candidateUrls = [];
    if (loc.host) {{
        candidateUrls.push(`${{proto}}//${{loc.host}}${{basePath}}/_stcore/terminal_stream`);
        if (basePath) {{
            candidateUrls.push(`${{proto}}//${{loc.host}}/_stcore/terminal_stream`);
        }}
    }}

    let fallbackHost = loc.hostname;
    if (!fallbackHost || fallbackHost === 'localhost') {{
        fallbackHost = '127.0.0.1';
    }}
    if (loc.protocol !== 'https:') {{
        candidateUrls.push(`ws://${{fallbackHost}}:{WS_PORT}`);
    }}

    let urlIdx = 0;
    let socket = null;
    let reconnectTimer = null;
    let hasSnapped = false;
    const textDecoder = new TextDecoder('utf-8');

    function closeCurrentSocket() {{
        if (reconnectTimer) {{
            clearTimeout(reconnectTimer);
            reconnectTimer = null;
        }}
        if (socket) {{
            socket.onopen = null;
            socket.onmessage = null;
            socket.onerror = null;
            socket.onclose = null;
            try {{
                socket.close();
            }} catch (e) {{}}
            socket = null;
        }}
    }}

    function connect() {{
        closeCurrentSocket();

        const targetUrl = candidateUrls[urlIdx % candidateUrls.length];
        statusEl.textContent = 'CONNECTING...';
        statusEl.className = 'status-badge';

        try {{
            const ws = new WebSocket(targetUrl);
            ws.binaryType = 'arraybuffer';
            socket = ws;

            let opened = false;

            ws.onopen = () => {{
                if (socket !== ws) return;
                opened = true;
                statusEl.textContent = 'LIVE (PTY)';
                statusEl.className = 'status-badge live';
                focusTerm();
                snapWindowToTerminal();
            }};

            ws.onmessage = (event) => {{
                if (socket !== ws) return;
                const text = (typeof event.data === 'string') ? event.data : textDecoder.decode(event.data);
                term.write(text, () => {{
                    if (!hasSnapped) {{
                        hasSnapped = true;
                        snapWindowToTerminal();
                    }}
                    if (socket && socket.readyState === WebSocket.OPEN) {{
                        socket.send("ack");
                    }}
                }});
            }};

            ws.onclose = () => {{
                if (socket !== ws) return;
                if (!opened && urlIdx + 1 < candidateUrls.length) {{
                    urlIdx++;
                    reconnectTimer = setTimeout(connect, 150);
                    return;
                }}
                statusEl.textContent = 'DISCONNECTED';
                statusEl.className = 'status-badge';
                reconnectTimer = setTimeout(connect, 1500);
            }};

            ws.onerror = () => {{
            }};
        }} catch(e) {{
            statusEl.textContent = 'ERR';
            statusEl.className = 'status-badge err';
        }}
    }}

    term.onData(data => {{
        if (socket && socket.readyState === WebSocket.OPEN) {{
            socket.send(data);
        }}
    }});

    window.addEventListener('load', () => {{
        connect();
        focusTerm();
        snapWindowToTerminal();
        setTimeout(snapWindowToTerminal, 100);
        setTimeout(snapWindowToTerminal, 300);
    }});
    window.addEventListener('resize', snapWindowToTerminal);
    window.addEventListener('click', focusTerm);
    setTimeout(focusTerm, 300);
    setTimeout(focusTerm, 1000);
</script>

</body>
</html>
"""

components.html(TERMINAL_HTML, height=920)
