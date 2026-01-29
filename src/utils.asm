option casemap:none
include constants.inc

extern GetStdHandle:proc
extern WriteFile:proc

.data
    hStdOut dq 0

.code

StrLen proc public
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

InitUtils proc public
    sub rsp, 40             ; Shadow space + alignment
    mov rcx, STD_OUTPUT_HANDLE
    call GetStdHandle
    mov [hStdOut], rax
    add rsp, 40
    ret
InitUtils endp

PrintString proc public
    push rbx                ; Save non-volatile RBX
    sub rsp, 48             ; Shadow space + written_ptr + alignment

    mov rbx, rcx            ; Store string pointer
    mov r10, [hStdOut]

    mov rcx, rbx
    call StrLen
    
    mov rcx, r10            ; hFile
    mov rdx, rbx            ; lpBuffer
    mov r8, rax             ; nNumberOfBytesToWrite
    lea r9, [rsp + 40]      ; lpNumberOfBytesWritten
    mov qword ptr [rsp + 32], 0 ; lpOverlapped
    call WriteFile

    add rsp, 48
    pop rbx
    ret
PrintString endp

end