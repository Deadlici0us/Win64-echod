; Set case sensitivity to none for labels and symbols
option casemap:none 

; External Windows functions
extern WSAStartup:proc
extern socket:proc
extern bind:proc
extern listen:proc
extern accept:proc
extern recv:proc
extern send:proc
extern closesocket:proc
extern WSACleanup:proc
extern CreateThread:proc
extern ExitThread:proc
extern ExitProcess:proc
extern GetStdHandle:proc
extern WriteFile:proc
extern htons:proc
extern CloseHandle:proc
extern WSAGetLastError:proc

; Constants for Windows API and Sockets
STD_OUTPUT_HANDLE equ -11             ; Handle for standard output
AF_INET           equ 2               ; IPv4 address family
SOCK_STREAM       equ 1               ; Stream socket (TCP)
IPPROTO_TCP       equ 6               ; TCP protocol
INVALID_SOCKET    equ -1
SOCKET_ERROR      equ -1
SOMAXCONN         equ 07FFFFFFFh
INADDR_ANY        equ 0

.data
    wsaData         db 400 dup(0)     ; Buffer for WSADATA structure (init by WSAStartup)
    port            dw 8080           ; Server port
    hStdOut         dq 0              ; Cached handle for standard output
    
    ; Null-terminated strings for console logging
    msgStart        db "Starting Echo Server on port 8080...", 13, 10, 0
    msgSocketErr    db "Socket creation failed.", 13, 10, 0
    msgBindErr      db "Bind failed.", 13, 10, 0
    msgListenErr    db "Listen failed.", 13, 10, 0
    msgAcceptErr    db "Accept failed.", 13, 10, 0
    msgClientCon    db "Client connected.", 13, 10, 0
    msgClientDis    db "Client disconnected.", 13, 10, 0

    msgRecvErr      db "Recv Error.", 13, 10, 0
    msgErrNotSock   db "Error: WSAENOTSOCK (Not a socket).", 13, 10, 0
    msgErrInval     db "Error: WSAEINVAL (Invalid argument).", 13, 10, 0
    msgErrFault     db "Error: WSAEFAULT (Bad address).", 13, 10, 0
    msgRecvZero     db "Recv returned 0 (Connection closed).", 13, 10, 0
    msgSendErr      db "Send Error.", 13, 10, 0
    msgThreadErr    db "Failed to create thread.", 13, 10, 0

.code

; ---------------------------------------------------------
; Helper: StrLen
; RCX = pointer to string
; Returns length in RAX (standard C-style string length)
; ---------------------------------------------------------
StrLen proc
    xor rax, rax
    test rcx, rcx
    jz done
next:
    cmp byte ptr [rcx + rax], 0
    je done
    inc rax
    jmp next
done:
    ret
StrLen endp

; ---------------------------------------------------------
; Helper: PrintString
; RCX = pointer to null-terminated string
; ---------------------------------------------------------
PrintString proc
    push rbx                ; Save non-volatile RBX; also aligns stack to 16 bytes
    sub rsp, 48             ; Allocate 32 bytes shadow space + 16 bytes for alignment/args
                            ; Win64 ABI requires 32 bytes shadow space for the callee

    mov rbx, rcx            ; Store string pointer in RBX (non-volatile)

    mov r10, [hStdOut]      ; Use the cached handle

    ; Calculate length
    mov rcx, rbx            ; String pointer
    call StrLen
    mov r8, rax             ; Length

    ; WriteFile(handle, str, len, written_ptr, overlapped)
    mov rcx, r10            ; hFile
    mov rdx, rbx            ; lpBuffer
                            ; r8 is already length
    lea r9, [rsp + 40]      ; lpNumberOfBytesWritten (local var safe slot)
    mov qword ptr [rsp + 32], 0 ; lpOverlapped (5th arg)
    call WriteFile

    add rsp, 48
    pop rbx
    ret
PrintString endp

; ---------------------------------------------------------
; ClientHandler
; ---------------------------------------------------------
ClientHandler proc
    ; RCX contains the client socket handle passed via lpParameter in CreateThread
    push rbx                ; Save non-volatile RBX
    
    ; Allocate 1024 bytes for data buffer + 32 bytes shadow space
    ; 1056 is a multiple of 16, maintaining stack alignment
    sub rsp, 1056           

    mov rbx, rcx            ; Store client socket in RBX
    
    lea rcx, [msgClientCon]
    call PrintString

echo_loop:
    ; recv(socket, buf, len, flags)
    mov rcx, rbx            ; Arg 1: socket handle
    lea rdx, [rsp + 32]     ; Arg 2: pointer to buffer (skipping shadow space)
    mov r8, 1024            ; Arg 3: buffer length
    mov r9, 0               ; Arg 4: flags
    call recv

    ; Check result (recv returns int)
    cmp eax, 0
    je recv_zero            ; 0 = closed
    cmp eax, -1
    je recv_error           ; -1 = error

    ; send(socket, buf, len, flags)
    mov rcx, rbx            ; Arg 1: socket handle
    lea rdx, [rsp + 32]     ; Arg 2: pointer to buffer
    movsxd r8, eax          ; Arg 3: length (bytes received from recv)
    mov r9, 0               ; Arg 4: flags
    call send

    cmp eax, -1             ; SOCKET_ERROR is -1
    je send_error

    jmp echo_loop

recv_zero:
    lea rcx, [msgRecvZero]
    call PrintString
    jmp close_and_exit

recv_error:
    call WSAGetLastError    ; Get specific Winsock error
    push rax                ; Save error code on stack
    sub rsp, 8              ; Align stack to 16 bytes (push subtracted 8)

    lea rcx, [msgRecvErr]
    call PrintString
    
    add rsp, 8              ; Clean up alignment space
    pop rax                 ; Restore error code to RAX

    ; Check common errors
    cmp eax, 10038 ; WSAENOTSOCK
    je err_notsock
    cmp eax, 10022 ; WSAEINVAL
    je err_inval
    cmp eax, 10014 ; WSAEFAULT
    je err_fault
    jmp close_and_exit

err_notsock:
    lea rcx, [msgErrNotSock]
    call PrintString
    jmp close_and_exit

err_inval:
    lea rcx, [msgErrInval]
    call PrintString
    jmp close_and_exit

err_fault:
    lea rcx, [msgErrFault]
    call PrintString
    jmp close_and_exit

send_error:
    lea rcx, [msgSendErr]
    call PrintString
    jmp close_and_exit

client_disconnect:
    lea rcx, [msgClientDis]
    call PrintString

close_and_exit:
    ; closesocket(socket)
    mov rcx, rbx
    call closesocket

    ; ExitThread(0)
    mov rcx, 0
    call ExitThread

    add rsp, 1056
    pop rbx
    ret
ClientHandler endp

; ---------------------------------------------------------
; Main Entry Point
; ---------------------------------------------------------
main proc
    ; Allocate shadow space (32) + space for sockaddr_in (16) + alignment/locals
    sub rsp, 88             

    ; Get and cache the standard output handle for PrintString
    mov rcx, STD_OUTPUT_HANDLE
    call GetStdHandle
    mov [hStdOut], rax

    ; 1. Initialize Winsock 2.2
    mov rcx, 0202h          ; Version 2.2
    lea rdx, wsaData
    call WSAStartup
    test rax, rax
    jnz exit_proc

    lea rcx, [msgStart]
    call PrintString

    ; 2. Create the listener socket
    mov rcx, AF_INET
    mov rdx, SOCK_STREAM
    mov r8, IPPROTO_TCP
    call socket
    cmp rax, INVALID_SOCKET
    je err_socket
    mov rdi, rax            ; Save server socket in RDI (non-volatile)

    ; 3. Prepare sockaddr_in structure on the stack
    ; struct sockaddr_in {
    ;     short sin_family;
    ;     u_short sin_port;
    ;     struct in_addr sin_addr;
    ;     char sin_zero[8];
    ; };
    ; Constructing at [rsp + 48]
    
    ; Clear the struct (16 bytes)
    mov qword ptr [rsp + 48], 0
    mov qword ptr [rsp + 56], 0

    mov word ptr [rsp + 48], AF_INET ; sin_family

    ; Convert port 8080 to network byte order
    mov rcx, 8080
    call htons
    mov word ptr [rsp + 50], ax      ; sin_port

    mov dword ptr [rsp + 52], INADDR_ANY ; sin_addr

    ; 4. Bind the socket to the address and port
    mov rcx, rdi            ; socket
    lea rdx, [rsp + 48]     ; ptr to sockaddr
    mov r8, 16              ; sizeof(sockaddr_in)
    call bind
    cmp eax, -1             ; SOCKET_ERROR
    je err_bind

    ; 5. Start listening for incoming connections
    mov rcx, rdi
    mov rdx, SOMAXCONN
    call listen
    cmp eax, -1             ; SOCKET_ERROR
    je err_listen

accept_loop:
    ; 6. Accept a new connection
    mov rcx, rdi
    mov rdx, 0
    mov r8, 0
    call accept
    cmp rax, INVALID_SOCKET
    je err_accept

    ; Connection successful. Socket handle is in RAX.
    mov rbx, rax            ; Move client socket to RBX (non-volatile) for safety

    ; 7. Create a new thread for the client
    ; CreateThread(NULL, 0, ClientHandler, socket, 0, NULL)
    mov rcx, 0              ; lpThreadAttributes
    mov rdx, 0              ; dwStackSize
    lea r8, ClientHandler   ; lpStartAddress
    mov r9, rbx             ; lpParameter (the socket)
    
    ; 5th and 6th args go on stack
    mov qword ptr [rsp + 32], 0 ; dwCreationFlags
    mov qword ptr [rsp + 40], 0 ; lpThreadId
    
    call CreateThread
    
    cmp rax, 0
    je err_thread
    
    ; Close the thread handle immediately (thread continues to run)
    mov rcx, rax
    call CloseHandle

    jmp accept_loop

err_socket:
    lea rcx, [msgSocketErr]
    call PrintString
    jmp clean_exit

err_bind:
    lea rcx, [msgBindErr]
    call PrintString
    jmp clean_exit

err_listen:
    lea rcx, [msgListenErr]
    call PrintString
    jmp clean_exit

err_accept:
    lea rcx, [msgAcceptErr]
    call PrintString
    jmp accept_loop

err_thread:
    lea rcx, [msgThreadErr]
    call PrintString
    ; Close the client socket since thread failed
    mov rcx, rbx
    call closesocket
    jmp accept_loop

clean_exit:
    mov rcx, rdi
    call closesocket
    call WSACleanup

exit_proc:
    mov rcx, 0
    call ExitProcess

main endp
end
