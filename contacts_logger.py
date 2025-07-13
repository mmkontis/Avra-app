#!/usr/bin/env python3
"""
Contacts Logger Server
Simple HTTP server that receives contacts from WhisperMe macOS app
and logs them line by line to the console
"""

from http.server import HTTPServer, BaseHTTPRequestHandler
import json
import sys
from datetime import datetime
from urllib.parse import urlparse
import threading

class ContactsHandler(BaseHTTPRequestHandler):
    def do_POST(self):
        """Handle POST requests to receive contacts"""
        parsed_path = urlparse(self.path)
        
        if parsed_path.path == '/contacts':
            try:
                # Get the content length
                content_length = int(self.headers.get('Content-Length', 0))
                
                # Read the request body
                post_data = self.rfile.read(content_length)
                
                # Parse JSON data
                contacts_data = json.loads(post_data.decode('utf-8'))
                
                # Log received contacts
                self.log_contacts(contacts_data)
                
                # Send success response
                self.send_response(200)
                self.send_header('Content-type', 'application/json')
                self.send_header('Access-Control-Allow-Origin', '*')
                self.end_headers()
                
                response = {
                    "status": "success",
                    "message": f"Received {len(contacts_data)} contacts",
                    "timestamp": datetime.now().isoformat()
                }
                
                self.wfile.write(json.dumps(response).encode('utf-8'))
                
            except Exception as e:
                print(f"❌ Error processing contacts: {str(e)}")
                self.send_error(500, f"Error processing contacts: {str(e)}")
        else:
            self.send_error(404, "Endpoint not found")
    
    def do_OPTIONS(self):
        """Handle OPTIONS requests for CORS"""
        self.send_response(200)
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')
        self.end_headers()
    
    def do_GET(self):
        """Handle GET requests for health check"""
        if self.path == '/health':
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.end_headers()
            
            response = {
                "status": "healthy",
                "message": "Contacts Logger Server is running",
                "timestamp": datetime.now().isoformat()
            }
            
            self.wfile.write(json.dumps(response).encode('utf-8'))
        else:
            self.send_error(404, "Endpoint not found")
    
    def log_contacts(self, contacts):
        """Log each contact line by line to the console"""
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        
        print(f"\n{'='*60}")
        print(f"📋 CONTACTS RECEIVED at {timestamp}")
        print(f"📊 Total contacts: {len(contacts)}")
        print(f"{'='*60}")
        
        for i, contact in enumerate(contacts, 1):
            first_name = contact.get('firstName', '')
            last_name = contact.get('lastName', '')
            display_name = contact.get('displayName', f"{first_name} {last_name}".strip())
            phone_number = contact.get('phoneNumber', '')
            formatted_phone = contact.get('formattedPhoneNumber', phone_number)
            
            print(f"{i:3d}. 👤 {display_name}")
            print(f"     📞 {formatted_phone}")
            if first_name or last_name:
                print(f"     📝 {first_name} {last_name}")
            print(f"     🔢 Raw: {phone_number}")
            print(f"     {'─'*40}")
        
        print(f"✅ Successfully logged {len(contacts)} contacts")
        print(f"{'='*60}\n")
    
    def log_message(self, format, *args):
        """Override log_message to customize server logs"""
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        sys.stdout.write(f"[{timestamp}] {format % args}\n")

def run_server(port=3001):
    """Run the contacts logger server"""
    server_address = ('localhost', port)
    httpd = HTTPServer(server_address, ContactsHandler)
    
    print(f"""
╔══════════════════════════════════════════════════════════════╗
║                    📋 Contacts Logger Server                 ║
║                                                              ║
║   🌐 Server running on: http://localhost:{port}                ║
║   📡 Endpoint: POST /contacts                                ║
║   🔍 Health check: GET /health                               ║
║                                                              ║
║   💡 Usage:                                                  ║
║   - Open WhisperMe macOS app                                 ║
║   - Click the status bar icon                                ║
║   - Click the contacts button (👥)                          ║
║   - Contacts will be logged here line by line               ║
║                                                              ║
║   ⏹️  Press Ctrl+C to stop the server                       ║
╚══════════════════════════════════════════════════════════════╝
    """)
    
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print(f"\n🛑 Server stopped by user")
        httpd.server_close()
        sys.exit(0)
    except Exception as e:
        print(f"\n❌ Server error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    # Check if a custom port is provided
    port = 3001
    if len(sys.argv) > 1:
        try:
            port = int(sys.argv[1])
        except ValueError:
            print("❌ Invalid port number. Using default port 3001.")
            port = 3001
    
    run_server(port) 