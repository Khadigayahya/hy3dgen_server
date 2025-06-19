import asyncio
import threading
import socket
from pyngrok import ngrok
import uvicorn
from main import app
import os

class NgrokServer:
    def __init__(self):
        self.server_running = False
        self.thread = None
        self.public_url = None

    def setup_ngrok(self, auth_token: str = None):
        """Setup ngrok tunnel"""
        try:
            # Set auth token if provided
            if auth_token:
                ngrok.set_auth_token(auth_token)
            
            # Kill any existing tunnels
            ngrok.kill()
            
            return True
        except Exception as e:
            print(f"Ngrok setup failed: {e}")
            return False

    def run_server(self, auth_token: str = None, port: int = None):
        """Run server with ngrok tunnel"""
        if self.server_running:
            print("⚠️ Server already running.")
            return None, None

        self.server_running = True

        # Setup ngrok
        if not self.setup_ngrok(auth_token):
            self.server_running = False
            return None, None

        # Get available port
        if port is None:
            sock = socket.socket()
            sock.bind(('', 0))
            port = sock.getsockname()[1]
            sock.close()

        # Create ngrok tunnel
        try:
            self.public_url = ngrok.connect(port)
            print(f"🌐 Public URL: {self.public_url}")
            print(f"📋 API Docs: {self.public_url}/docs")
            print(f"🔍 Try it: {self.public_url}/")
        except Exception as e:
            print(f"Failed to create ngrok tunnel: {e}")
            self.server_running = False
            return None, None

        # Setup uvicorn server
        config = uvicorn.Config(app=app, host="0.0.0.0", port=port, log_level="info")
        server = uvicorn.Server(config)

        def start_server():
            loop = asyncio.new_event_loop()
            asyncio.set_event_loop(loop)
            loop.run_until_complete(server.serve())

        self.thread = threading.Thread(target=start_server, daemon=True)
        self.thread.start()

        print("✅ Server started successfully!")
        return self.thread, self.public_url

    def stop_server(self):
        """Stop the server and ngrok"""
        try:
            ngrok.kill()
            self.server_running = False
            print("✅ Server stopped successfully!")
        except Exception as e:
            print(f"Error stopping server: {e}")

# Example usage
if __name__ == "__main__":
    # Get auth token from environment or use default
    auth_token = os.getenv("NGROK_AUTH_TOKEN", "2yb65kKzHx9UuVBLWg23TXFVuIf_45ZSirRRSmshn7HRoRJNR")
    
    server = NgrokServer()
    thread, public_url = server.run_server(auth_token=auth_token)
    
    if public_url:
        print(f"""
🚀 Your 3D Model Generator API is now running!

📋 Usage Instructions:
1. Visit the public URL to see the API status
2. Go to /docs for interactive API documentation
3. Use /generate-3d endpoint to upload images and get 3D models

🔧 Endpoints:
- GET /         - API status
- GET /health   - Detailed health check
- POST /generate-3d - Generate 3D model from image

Public URL: {public_url}
        """)
        
        try:
            # Keep the main thread alive
            thread.join()
        except KeyboardInterrupt:
            server.stop_server()