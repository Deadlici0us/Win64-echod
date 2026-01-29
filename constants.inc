; Constants for Windows API and Sockets
STD_OUTPUT_HANDLE equ -11
AF_INET           equ 2
SOCK_STREAM       equ 1
IPPROTO_TCP       equ 6
INVALID_SOCKET    equ -1
SOCKET_ERROR      equ -1
SOMAXCONN         equ 07FFFFFFFh
INADDR_ANY        equ 0
WSA_VERSION       equ 0202h

; Winsock Error Codes
WSAENOTSOCK       equ 10038
WSAEINVAL         equ 10022
WSAEFAULT         equ 10014

sockaddr_in STRUCT
    sin_family WORD ?
    sin_port WORD ?
    sin_addr DWORD ?
    sin_zero BYTE 8 DUP(?)
sockaddr_in ENDS