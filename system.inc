; Win32 System Constants
STD_OUTPUT_HANDLE equ -11
INVALID_HANDLE_VALUE equ -1
INFINITE          equ 0FFFFFFFFh

; Standard Types
NULL              equ 0
TRUE              equ 1
FALSE             equ 0

; Externs (Kernel32)
extern CreateIoCompletionPort:proc
extern GetQueuedCompletionStatus:proc
extern CreateThread:proc
extern CloseHandle:proc
extern GetProcessHeap:proc
extern HeapAlloc:proc
extern HeapFree:proc
extern ExitThread:proc
extern GetSystemInfo:proc