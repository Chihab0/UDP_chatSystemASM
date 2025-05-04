BITS 64

section .data
    prefix      db "I'm just copying: ", 0
    prefix_len  equ $ - prefix
    quit_msg    db "quit", 0
    msg_recv    db "[+] Message received", 0xA
    msg_quit    db "[!] Quit received", 0xA
    msg_send    db "[>] Sending response", 0xA
    msg_loop    db "[.] Listening again", 0xA

section .bss
    recv_buf        resb 1024
    send_buf        resb 1050
    client_addr     resb 128
    client_addr_len resq 1

section .text
    global _start

_start:
    ; socket(AF_INET, SOCK_DGRAM, 0)
    mov     rax, 41         ; sys_socket
    mov     rdi, 2          ; AF_INET
    mov     rsi, 2          ; SOCK_DGRAM UDP
    xor     rdx, rdx        ; protocol
    syscall
    mov     r12, rax        ; save socket fd in r12

    ; bind(sock, sockaddr_in, addrlen)
    sub     rsp, 16
    mov     word [rsp], 2          ; AF_INET
    mov     word [rsp+2], 0x3905   ; port 1337 (0x0539) in LE
    mov     dword [rsp+4], 0       ; INADDR_ANY
    mov     qword [rsp+8], 0       ; padding

    mov     rax, 49         ; sys_bind
    mov     rdi, r12        ; socket fd
    mov     rsi, rsp        ; pointer to sockaddr
    mov     rdx, 16         ; addrlen
    syscall

.listen_loop:
    mov     qword [client_addr_len], 128

    ; recvfrom(sock, recv_buf, 1024, 0, client_addr, &len)
    mov     rax, 45         ; sys_recvfrom
    mov     rdi, r12        ; socket
    lea     rsi, [rel recv_buf]
    mov     rdx, 1024
    xor     r10, r10        ; flags = 0
    lea     r8, [rel client_addr]
    lea     r9, [rel client_addr_len]
    syscall
    cmp     rax, 0
    jle     .listen_loop    ; skip if no bytes or error
    mov     r13, rax        ; r13 = bytes received

    mov     byte [recv_buf + r13], 0

    ; write debug
    mov     rax, 1
    mov     rdi, 1
    lea     rsi, [rel msg_recv]
    mov     rdx, 23
    syscall

    ; compare with "quit"
    lea     rsi, [rel recv_buf]
    lea     rdi, [rel quit_msg]
    call    str_eq
    cmp     rax, 1
    jne     .not_quit

    ; debug quit
    mov     rax, 1
    mov     rdi, 1
    lea     rsi, [rel msg_quit]
    mov     rdx, 20
    syscall
    jmp     .exit_server

.not_quit:
    ; build send_buf = prefix + message
    lea     rdi, [rel send_buf]
    lea     rsi, [rel prefix]
    mov     rcx, prefix_len
    call    memcpy

    lea     rdi, [send_buf + prefix_len]
    lea     rsi, [recv_buf]
    mov     rcx, r13
    call    memcpy

    ; debug send
    mov     rax, 1
    mov     rdi, 1
    lea     rsi, [rel msg_send]
    mov     rdx, 23
    syscall

    ; sendto(sock, send_buf, len, 0, client_addr, addrlen)
    mov     rax, 44         ; sys_sendto
    mov     rdi, r12        ; socket
    lea     rsi, [rel send_buf]
    mov     rdx, r13
    add     rdx, prefix_len
    xor     r10, r10        ; flags
    lea     r8, [rel client_addr]
    mov     r9, [client_addr_len]
    syscall

    ; loop debug
    mov     rax, 1
    mov     rdi, 1
    lea     rsi, [rel msg_loop]
    mov     rdx, 22
    syscall

    jmp     .listen_loop

.exit_server:
    mov     rax, 60         ; sys_exit
    xor     rdi, rdi
    syscall


; rdi = dest, rsi = src, rcx = count
memcpy:
    push    rbx
.memcpy_loop:
    cmp     rcx, 0
    je      .memcpy_done
    mov     bl, byte [rsi]
    mov     byte [rdi], bl
    inc     rsi
    inc     rdi
    dec     rcx
    jmp     .memcpy_loop
.memcpy_done:
    pop     rbx
    ret


; strcmp-like equality check
; rdi = str1, rsi = str2
; returns rax = 1 if equal, 0 otherwise
str_eq:
    push    rbx
.next_char:
    mov     al, [rdi]
    mov     bl, [rsi]
    cmp     al, bl
    jne     .not_equal
    test    al, al
    je      .equal
    inc     rdi
    inc     rsi
    jmp     .next_char
.equal:
    mov     rax, 1
    pop     rbx
    ret
.not_equal:
    xor     rax, rax
    pop     rbx
    ret

