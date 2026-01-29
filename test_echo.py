import socket
import sys
import time

HOST = '127.0.0.1'
PORT = 8080

def test_server():
    print(f"Connecting to {HOST}:{PORT}...")
    try:
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
            s.settimeout(5) # 5 second timeout
            s.connect((HOST, PORT))
            print("Connected.")
            msg = b'Hello, World!'
            print(f"Sending: {msg}")
            s.sendall(msg)
            data = s.recv(1024)
            print(f"Received: {data}")
            if data == msg:
                print("Test Passed")
            else:
                print("Test Failed: Data mismatch")
    except ConnectionRefusedError:
        print("Test Failed: Connection refused. Is the server running?")
    except Exception as e:
        print(f"Test Failed: {e}")

if __name__ == "__main__":
    test_server()
