%include "syscall.mac"

%define ICANON 1<1
%define ECHO   1<3
%define TCGETS 21505 ; attr to get struct
%define TCPUTS 21506 ; attr to put struct

section .bss

; termios structs
stty resb 12
slflag resb 12 ; flags
srest resb 44

tty resb 12
lflag resb 12
brest resb 44

section .text

global set_noncanon
global set_canon

set_noncanon:
	; store old termios
	mov rax, stty
	mov rdx, TCGETS
	call term_attr

	; store termios
	mov rax, tty
	mov rdx, TCGETS
	call term_attr

	; remove icanon and echo flags
	and dword [lflag], (~ICANON)
	and dword [lflag], (~ECHO)

	; set attrs
	mov rax, tty
	mov rdx, TCPUTS
	call term_attr
	ret

set_canon:
	; restore from saved termios struct
	mov rax, stty
	mov rdx, TCPUTS
	call term_attr
	ret

; rax - termios struct pointer
; rdx - TCGETS or TCPUTS
term_attr:
	push rdi
	push rsi

	mov rsi, rdx
	mov rdx, rax
	mov rax, SYSCALL_IOCTL
	mov rdi, 0
	syscall

	pop rsi
	pop rdi
	ret

section .data

; poll function struct arg
spoll:
	dd 0 ; fd
	dw 1 ; events
	dw 0 ; revents

section .text

global poll

; rax: address to save input to
poll:
	push rdi
	push rsi

	push rax ; save input addr

	; poll event
	mov rax, SYSCALL_POLL
	mov rdi, spoll ; pointer to struct
	mov rsi, 1 ; only 1 fd - stdin
	mov rdx, 0 ; timeout
	syscall

	pop rsi ; restore input addr

	test rax, rax ; test if no event
	jz poll_no_event

	; read input
	mov rax, SYSCALL_READ
	mov rdi, 0 ; stdin fd
	; rsi: address to store input in
	mov rdx, 1 ; read one character
	syscall

	jmp poll_exit

	poll_no_event:
		mov byte [rsi], 0

	poll_exit:
		pop rsi
		pop rdi
		ret

; vim:ft=nasm
