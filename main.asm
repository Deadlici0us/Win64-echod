; Set case sensitivity to none for labels and symbols
option casemap:none 
include constants.inc

; External Windows functions
extern accept:proc
extern recv:proc
extern send:proc
extern closesocket:proc
extern WSACleanup:proc
extern QueueUserWorkItem:proc
extern ExitProcess:proc
extern WSAGetLastError:proc

; External Modular functions
extern InitUtils:proc
extern PrintString:proc
extern InitNetwork:proc
extern CreateListener:proc
extern ClientHandler:proc

.data
    ; Null-terminated strings for console logging
    msgStart        db "Starting Echo Server on port 8080...", 13, 10, 0
    msgSocketErr    db "Socket creation failed.", 13, 10, 0
    msgBindErr      db "Bind failed.", 13, 10, 0
    msgListenErr    db "Listen failed.", 13, 10, 0
    msgAcceptErr    db "Accept failed.", 13, 10, 0
    msgThreadErr    db "Failed to queue work item.", 13, 10, 0

.code

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
    mov rcx, DEFAULT_PORT
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

    ; 7. Submit to Windows Thread Pool
    ; QueueUserWorkItem(ClientHandler, socket, WT_EXECUTEDEFAULT)
    mov rcx, ClientHandler  ; Function
    mov rdx, rbx            ; Context (socket)
    mov r8, 0               ; Flags (WT_EXECUTEDEFAULT = 0)
    call QueueUserWorkItem

    test eax, eax           ; Returns non-zero on success
    jz err_thread

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
