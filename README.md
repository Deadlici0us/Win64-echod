# Win64-echod

A high-performance, I/O Completion Port (IOCP) based TCP Echo Server written entirely in **x64 Assembly (MASM)** for Windows.

This project is a showcase of low-level systems programming, demonstrating manual memory management, Win32 API integration, and enterprise-grade concurrency models without the safety net of a high-level language.

## 🚀 Features

### 1. IOCP Architecture (Scalable)
Unlike simple one-thread-per-connection examples, `win64-echod` uses the Windows **I/O Completion Ports (IOCP)** model, which is the standard for high-performance Windows networking (used by IIS, SQL Server, etc.).
- **Concurrency:** A fixed pool of worker threads (2x CPU cores) services thousands of concurrent connections.
- **Efficiency:** Threads are only active when an I/O operation completes, eliminating context-switching overhead from idle connections.
- **Asynchronous I/O:** Uses `WSARecv` and `WSASend` with `WSAOVERLAPPED` structures to perform non-blocking I/O.

### 2. Low-Level Win64 ABI Compliance
The codebase demonstrates a deep understanding of the Windows x64 Calling Convention:
- **Shadow Space:** Explicit allocation of the required 32-byte "home space" for API calls.
- **Stack Alignment:** Strict adherence to the 16-byte stack alignment requirement.
- **Register Preservation:** Proper management of non-volatile registers (`RBX`, `RDI`, `RSI`, `R12`-`R15`).

### 3. Winsock2 Integration
Direct implementation of the Berkeley Sockets API via `Ws2_32.lib`:
- **Overlapped I/O:** Manages `WSAOVERLAPPED` structures manually on the Heap.
- **Network Byte Order:** Conversions using `htons`.
- **Error Handling:** Comprehensive checking using `WSAGetLastError` and handling `WSA_IO_PENDING`.

### 4. Modern Build System
The project uses **CMake** to bridge the gap between assembly and modern development workflows. It supports:
- Automated discovery of `ml64.exe` (MASM).
- Debug and Release build configurations.
- Linker optimizations like `/OPT:REF` and `/OPT:ICF` for lean Release binaries.

## 🛠 Technical Deep Dive

### The Architecture
The server follows the Proactor pattern using IOCP:
1.  **Initialization:** `WSAStartup` prepares Winsock. `CreateIoCompletionPort` creates the completion queue.
2.  **Thread Pool:** `GetSystemInfo` detects CPU cores, and a pool of threads is spawned using `CreateThread`. All threads block on `GetQueuedCompletionStatus`.
3.  **Accept Loop:** The main thread accepts connections. Upon acceptance, the new socket is associated with the IOCP handle via `CreateIoCompletionPort`.
4.  **Async Cycle:** A `WSARecv` is posted immediately. When data arrives, a worker thread wakes up, processes the data (Echo), and posts a `WSASend`. When the send completes, another `WSARecv` is posted.

### Memory Management
- **Context Structure:** Each I/O operation tracks its state using a custom `IO_CONTEXT` structure allocated from the Process Heap (`GetProcessHeap`, `HeapAlloc`).
- **Zero-Copy Intent:** The `WSABUF` points directly to the buffer inside the `IO_CONTEXT`, ensuring data stays pinned during async operations.

### x64 Calling Convention Implementation
Unlike x86, x64 requires careful attention to the stack. This project manually handles:
- **Register-based Argument Passing:** Utilizing `RCX`, `RDX`, `R8`, and `R9` for the first four arguments.
- **Shadow Space:** Allocating 32 bytes on the stack before every function call.

## 🧪 Testing Suite

The server is paired with a Python-based testing suite to validate both functionality and concurrency.

- **`test_echo.py`**: A functional test that validates the basic request-response integrity.
- **`test_concurrency.py`**: A stress test that spawns multiple Python threads to hammer the server, ensuring the IOCP logic handles race conditions correctly.

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
