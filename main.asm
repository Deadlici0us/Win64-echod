; Set case sensitivity to none for labels and symbols
option casemap:none 
include constants.inc

; External Windows functions
extern accept:proc
extern recv:proc
extern send:proc
extern closesocket:proc
extern WSACleanup:proc
extern CreateThread:proc
extern ExitThread:proc
extern ExitProcess:proc
extern CloseHandle:proc
extern WSAGetLastError:proc

; External Modular functions
extern InitUtils:proc
extern PrintString:proc
extern InitNetwork:proc
extern CreateListener:proc

.data
    serverPort      dq 8080
    
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
    cmp eax, WSAENOTSOCK
    je err_notsock
    cmp eax, WSAEINVAL
    je err_inval
    cmp eax, WSAEFAULT
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
    ; Allocate shadow space (32) + CreateThread args (16) + alignment (8)
    sub rsp, 56             

    call InitUtils
    call InitNetwork
    test rax, rax
    jnz exit_proc

    lea rcx, [msgStart]
    call PrintString

    ; Create the listener socket via modular helper
    mov rcx, [serverPort]
    call CreateListener
    cmp rax, INVALID_SOCKET
    je clean_exit
    mov rdi, rax            ; Save server socket in RDI (non-volatile)
    ; };

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
