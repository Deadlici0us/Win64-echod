import socket
import sys
import time

HOST = '127.0.0.1'
PORT = 8080

def test_server():
    max_retries = 3
    for i in range(max_retries):
        try:
            print(f"Connecting to {HOST}:{PORT} (Attempt {i+1}/{max_retries})...")
            s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            s.settimeout(5)
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
            s.close()
            return
        except (ConnectionRefusedError, socket.timeout):
            if i < max_retries - 1:
                time.sleep(1)
                continue
            print("Test Failed: Connection refused or timed out.")
        except Exception as e:
            print(f"Test Failed: {e}")
            break

if __name__ == "__main__":
    test_server()
