option casemap:none
include constants.inc

extern recv:proc
extern send:proc
extern closesocket:proc
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
; ProcessRequest
; Purpose:  Abstracts the business logic (SRP). 
;           Currently implements Echo, but can be swapped for HTTP.
; Args:     RCX = Pointer to Buffer
;           RDX = Length of data
; Returns:  RAX = Length of response (in this case, same as input)
; ---------------------------------------------------------
ProcessRequest proc private
    ; For a simple Echo, we don't need to do anything as the
    ; input buffer is reused as the output buffer.
    ; In a real HTTP server, this would parse the request in [RCX]
    ; and write the response to [RCX] (or a new buffer).
    
    mov rax, rdx    ; Return the length of data to send
    ret
ProcessRequest endp

; ---------------------------------------------------------
; ClientHandler
; Purpose:  Manages the connection lifecycle (recv loop).
;           Compatible with QueueUserWorkItem (Thread Pool).
; ---------------------------------------------------------
ClientHandler proc public
    ; RCX contains the client socket handle
    ; Note: QueueUserWorkItem callbacks must return 0 and use 'ret', NOT ExitThread.
    
    push rbx                ; Save non-volatile RBX
    push rsi                ; Save non-volatile RSI
    
    ; Allocate data buffer + 32 bytes shadow space
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
    lea rdx, [rsp + 32]     ; Arg 2: pointer to buffer
    mov r8, BUFFER_SIZE     ; Arg 3: buffer length
    mov r9, 0               ; Arg 4: flags
    call recv

    ; Check result
    cmp eax, 0
    je recv_zero            ; 0 = closed
    cmp eax, -1
    je recv_error           ; -1 = error

    ; -----------------------------------------------------
    ; Business Logic Separation (SRP)
    ; -----------------------------------------------------
    lea rcx, [rsp + 32]     ; Ptr to data
    movsxd rdx, eax         ; Length of data
    call ProcessRequest
    ; RAX now contains length to send
    mov rsi, rax            ; Save length in RSI

    ; -----------------------------------------------------
    ; Send Response
    ; -----------------------------------------------------
    mov rcx, rbx            ; Arg 1: socket handle
    lea rdx, [rsp + 32]     ; Arg 2: pointer to buffer
    mov r8, rsi             ; Arg 3: length
    mov r9, 0               ; Arg 4: flags
    call send

    cmp eax, -1
    je send_error

    jmp echo_loop

recv_zero:
    lea rcx, [msgRecvZero]
    call PrintString
    jmp close_and_exit

recv_error:
    call WSAGetLastError
    ; Error handling logic...
    ; (Simplified for brevity, but could delegate to ErrorHandler)
    lea rcx, [msgRecvErr]
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

    ; Return cleanly for Thread Pool compatibility
    mov rax, 0
    add rsp, BUFFER_SIZE + 32
    pop rsi
    pop rbx
    ret
ClientHandler endp

end
