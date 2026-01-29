option casemap:none
include constants.inc

extern WSAStartup:proc
extern socket:proc
extern bind:proc
extern listen:proc
extern htons:proc
extern closesocket:proc

.data
    wsaData db 400 dup(0)

.code

InitNetwork proc public
    sub rsp, 40
    mov rcx, WSA_VERSION
    lea rdx, wsaData
    call WSAStartup
    add rsp, 40
    ret
InitNetwork endp

CreateListener proc public
    ; RCX = port
    push rsi
    push rdi
    sub rsp, 56             ; Shadow space + sockaddr_in (16) + alignment

    mov rsi, rcx            ; Save port

    ; socket(AF_INET, SOCK_STREAM, IPPROTO_TCP)
    mov rcx, AF_INET
    mov rdx, SOCK_STREAM
    mov r8, IPPROTO_TCP
    call socket
    cmp rax, INVALID_SOCKET
    je done

    mov rdi, rax            ; Save socket

    ; Prepare sockaddr_in using the struct
    lea rdx, [rsp + 32]
    mov word ptr [rdx + sockaddr_in.sin_family], AF_INET
    
    mov rcx, rsi            ; port
    call htons
    lea rdx, [rsp + 32]
    mov word ptr [rdx + sockaddr_in.sin_port], ax
    mov dword ptr [rdx + sockaddr_in.sin_addr], INADDR_ANY

    ; bind(socket, sockaddr, sizeof)
    mov rcx, rdi
    lea rdx, [rsp + 32]
    mov r8, size sockaddr_in
    call bind
    cmp eax, SOCKET_ERROR
    je err_close

    ; listen(socket, SOMAXCONN)
    mov rcx, rdi
    mov rdx, SOMAXCONN
    call listen
    cmp eax, SOCKET_ERROR
    je err_close

    mov rax, rdi            ; Return socket
    jmp done

err_close:
    mov rcx, rdi
    call closesocket
    mov rax, INVALID_SOCKET

done:
    add rsp, 56
    pop rdi
    pop rsi
    ret
CreateListener endp

end