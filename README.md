# Win64-echod

A high-performance, multi-threaded TCP Echo Server written entirely in **x64 Assembly (MASM)** for Windows.

This project is a showcase of low-level systems programming, demonstrating manual memory management, Win32 API integration, and robust concurrency models without the safety net of a high-level language.

## 🚀 Features

### 1. Multi-Threaded Architecture
Unlike simple single-threaded examples, `win64-echod` utilizes a **one-thread-per-connection** model. 
- **Concurrency:** The main loop accepts incoming connections and immediately spawns a new worker thread using `CreateThread`.
- **Scalability:** Each `ClientHandler` operates independently, allowing the server to handle multiple simultaneous echo sessions.
- **Resource Management:** Thread handles are closed immediately after creation to prevent resource leaks, while the thread continues execution.

### 2. Low-Level Win64 ABI Compliance
The codebase demonstrates a deep understanding of the Windows x64 Calling Convention:
- **Shadow Space:** Explicit allocation of the required 32-byte "home space" for API calls.
- **Stack Alignment:** Strict adherence to the 16-byte stack alignment requirement before calling external functions.
- **Register Preservation:** Proper management of non-volatile registers (`RBX`, `RDI`, `RSI`) to ensure system stability.

### 3. Winsock2 Integration
Direct implementation of the Berkeley Sockets API via `Ws2_32.lib`:
- Manual construction of `sockaddr_in` structures on the stack.
- Network byte order conversions using `htons`.
- Comprehensive error checking using `WSAGetLastError` with specific diagnostic messages for `WSAENOTSOCK`, `WSAEINVAL`, and `WSAEFAULT`.

### 4. Modern Build System
The project uses **CMake** to bridge the gap between assembly and modern development workflows. It supports:
- Automated discovery of `ml64.exe` (MASM).
- Debug and Release build configurations.
- Linker optimizations like `/OPT:REF` and `/OPT:ICF` for lean Release binaries.

## 🛠 Technical Deep Dive

### The Architecture
The server follows a standard socket lifecycle but is optimized for concurrency and modularity:
- **Initialization:** `WSAStartup` prepares the Winsock library.
- **Listener Setup:** Creates a `SOCK_STREAM` (TCP) socket, enables `SO_REUSEADDR` for immediate restarts, binds to `0.0.0.0:8080`, and enters a listening state.
- **The Accept Loop:** The main thread blocks on `accept`. Upon connection, the socket handle is passed as a parameter to a new thread.
- **Client Handler (handler.asm):** Each thread manages its own stack-allocated buffer (defined by `BUFFER_SIZE`), enabling `TCP_NODELAY` for low-latency response, and performing a `recv` -> `send` (echo) loop.

### Performance Roadmap
While the current model is robust, future optimizations include:
- **IOCP (I/O Completion Ports):** Moving away from one-thread-per-connection to a scalable completion port model.
- **Zero-Copy Echo:** Utilizing `TransmitFile` or optimized buffer pooling to reduce stack pressure.

### x64 Calling Convention Implementation
Unlike x86, x64 requires careful attention to the stack. This project manually handles:
- **Register-based Argument Passing:** Utilizing `RCX`, `RDX`, `R8`, and `R9` for the first four arguments.
- **Shadow Space:** Allocating 32 bytes on the stack before every function call to provide the callee space to spill registers.
- **Non-Volatile Register Preservation:** Safely pushing/popping `RBX` and `RDI` to maintain system stability.

### The Echo Loop
The core logic resides in `ClientHandler`. It uses a 1024-byte buffer allocated directly on the stack. By leveraging `movsxd` for sign-extension and efficient register usage, the server achieves near-zero overhead in data echoing.

### String Handling
Since assembly lacks a standard library, the project includes custom-built helpers like `StrLen` and `PrintString` which interface directly with `GetStdHandle` and `WriteFile` for thread-safe console logging.

## 🧪 Testing Suite

The server is paired with a Python-based testing suite to validate both functionality and concurrency.

- **`test_echo.py`**: A functional test that validates the basic request-response integrity.
- **`test_concurrency.py`**: A stress test that spawns 10 simultaneous Python threads to hammer the server, ensuring the MASM threading logic handles race conditions and socket handoffs correctly.

## 🏗 Building and Running

### Prerequisites
- Visual Studio Build Tools (with MASM/x64 support)
- CMake 3.10+
- Python 3.x (for testing)

### Build
You can use the provided helper script:
```powershell
.\build.ps1
```

Or manually:
```powershell
mkdir build
cd build
cmake ..
cmake --build .
```

### Run Server
```powershell
.\run_server.ps1
```

### Run Tests
```powershell
.\run_tests.ps1
```

---

## 📜 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.