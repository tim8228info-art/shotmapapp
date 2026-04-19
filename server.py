import http.server
import socketserver
import os

PORT = 5060
DIRECTORY = "/home/user/webapp/build/web"

class Handler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=DIRECTORY, **kwargs)

    def end_headers(self):
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', '*')
        self.send_header('Content-Security-Policy',
            "frame-ancestors *; default-src * 'unsafe-inline' 'unsafe-eval' data: blob:; "
            "script-src * 'unsafe-inline' 'unsafe-eval'; img-src * data: blob:; connect-src *; frame-src *;"
        )
        super().end_headers()

    def log_message(self, format, *args):
        pass

os.chdir(DIRECTORY)
with socketserver.TCPServer(('0.0.0.0', PORT), Handler) as httpd:
    httpd.allow_reuse_address = True
    print(f"Shot map server running on port {PORT}")
    httpd.serve_forever()
