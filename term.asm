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
	push rax
	push rbx

	; store old termios
	mov rax, stty
	mov rbx, TCGETS
	call term_attr

	; store termios
	mov rax, tty
	mov rbx, TCGETS
	call term_attr

	; remove icanon and echo flags
	and dword [lflag], (~ICANON)
	and dword [lflag], (~ECHO)

	; set attrs
	mov rax, tty
	mov rbx, TCPUTS
	call term_attr

	pop rbx
	pop rax
	ret

set_canon:
	push rax
	push rbx

	mov rax, stty
	mov rbx, TCPUTS
	call term_attr

	pop rbx
	pop rax
	ret

; rax - termios struct pointer
; rbx - TCGETS or TCPUTS
term_attr:
	push rax
	push rdi
	push rsi
	push rdx

	mov rdx, rax
	mov rsi, rbx
	mov rax, 16 ; ioctl system call
	mov rdi, 0
	syscall

	pop rdx
	pop rsi
	pop rdi
	pop rax
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
	push rax
	push rdi
	push rsi
	push rdx

	push rax ; save input addr

	; poll event
	mov rax, 7 ; poll system call
	mov rdi, spoll ; pointer to struct
	mov rsi, 1 ; only 1 fd - stdin
	mov rdx, 0 ; timeout
	syscall

	pop rsi ; restore input addr

	test rax, rax ; test if no event
	jz poll_no_event

	; read input
	mov rax, 0 ; read system call
	mov rdi, 0 ; stdin fd
	; rsi: address to store input in
	mov rdx, 1 ; read one character
	syscall

	jmp poll_exit

	poll_no_event:
		mov byte [rsi], 0

	poll_exit:
		pop rdx
		pop rsi
		pop rdi
		pop rax
		ret

; vim:ft=nasm
