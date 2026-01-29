import socket
import threading
import time
import sys

HOST = '127.0.0.1'
PORT = 8080
CLIENT_COUNT = 10
MSG_PREFIX = b'Message from client '

success_count = 0
lock = threading.Lock()

def client_task(client_id):
    global success_count
    msg = MSG_PREFIX + str(client_id).encode()
    try:
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
            s.settimeout(5)
            s.connect((HOST, PORT))
            s.sendall(msg)
            data = s.recv(1024)
            if data == msg:
                with lock:
                    success_count += 1
            else:
                print(f"Client {client_id}: Mismatch. Sent {msg}, got {data}")
    except Exception as e:
        print(f"Client {client_id}: Error: {e}")

def wait_for_server(host, port, timeout=5):
    """Wait for the server to be ready to accept connections."""
    start_time = time.time()
    while time.time() - start_time < timeout:
        try:
            with socket.create_connection((host, port), timeout=1):
                return True
        except (ConnectionRefusedError, socket.timeout):
            time.sleep(0.1)
    return False

def run_test():
    if not wait_for_server(HOST, PORT):
        print(f"Error: Server at {HOST}:{PORT} not responding.")
        sys.exit(1)
        
    print(f"Starting {CLIENT_COUNT} clients...")
    threads = []
    for i in range(CLIENT_COUNT):
        t = threading.Thread(target=client_task, args=(i,))
        threads.append(t)
        t.start()
    
    for t in threads:
        t.join()

    print(f"Finished. Success: {success_count}/{CLIENT_COUNT}")
    if success_count == CLIENT_COUNT:
        print("Concurrency Test PASSED")
        sys.exit(0)
    else:
        print("Concurrency Test FAILED")
        sys.exit(1)

if __name__ == "__main__":
    run_test()
