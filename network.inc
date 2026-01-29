; Winsock2 Constants and Structures
AF_INET           equ 2
SOCK_STREAM       equ 1
IPPROTO_TCP       equ 6
SOMAXCONN         equ 07FFFFFFFh
INADDR_ANY        equ 0
WSA_VERSION       equ 0202h

; Performance Optimization: Disable Nagle's Algorithm
TCP_NODELAY       equ 1

; Socket Options
SOL_SOCKET        equ 0FFFFh
SO_REUSEADDR      equ 4

; Configuration
BUFFER_SIZE       equ 1024
DEFAULT_PORT      equ 8080

; Socket Error Codes
INVALID_SOCKET    equ 0FFFFFFFFFFFFFFFFh ; Explicit 64-bit -1
SOCKET_ERROR      equ -1
WSAENOTSOCK       equ 10038
WSAEINVAL         equ 10022
WSAEFAULT         equ 10014

; Structures
sockaddr_in STRUCT
    sin_family WORD ?
    sin_port WORD ?
    sin_addr DWORD ?
    sin_zero BYTE 8 DUP(?)
sockaddr_in ENDS