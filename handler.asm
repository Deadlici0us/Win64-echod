option casemap:none
include constants.inc

extern recv:proc
extern send:proc
extern closesocket:proc
extern ExitThread:proc
extern WSAGetLastError:proc
extern PrintString:proc
extern EnableNoDelay:proc

.data
    msgClientCon    db "Client connected.", 13, 10, 0
    msgClientDis    db "Client disconnected.", 13, 10, 0
    msgRecvErr      db "Recv Error.", 13, 10, 0
    msgErrNotSock   db "Error: WSAENOTSOCK (Not a socket).", 13, 10, 0
    msgErrInval     db "Error: WSAEINVAL (Invalid argument).", 13, 10, 0
    msgErrFault     db "Error: WSAEFAULT (Bad address).", 13, 10, 0
    msgRecvZero     db "Recv returned 0 (Connection closed).", 13, 10, 0
    msgSendErr      db "Send Error.", 13, 10, 0

.code

; ---------------------------------------------------------
; ClientHandler
; ---------------------------------------------------------
ClientHandler proc public
    ; RCX contains the client socket handle passed via lpParameter in CreateThread
    push rbx                ; Save non-volatile RBX
    
    ; Allocate data buffer + 32 bytes shadow space
    ; Ensure stack stays 16-byte aligned. BUFFER_SIZE (1024) + 32 = 1056 (aligned)
    sub rsp, BUFFER_SIZE + 32           

    mov rbx, rcx            ; Store client socket in RBX
    
    ; Optimization: Enable TCP_NODELAY
    mov rcx, rbx
    call EnableNoDelay

    lea rcx, [msgClientCon]
    call PrintString

echo_loop:
    ; recv(socket, buf, len, flags)
    mov rcx, rbx            ; Arg 1: socket handle
    lea rdx, [rsp + 32]     ; Arg 2: pointer to buffer (skipping shadow space)
    mov r8, BUFFER_SIZE     ; Arg 3: buffer length
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

    add rsp, BUFFER_SIZE + 32
    pop rbx
    ret
ClientHandler endp

end
