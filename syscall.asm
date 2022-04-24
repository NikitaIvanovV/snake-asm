%include "print.mac"
%include "syscall_int.mac"

%define READ      0
%define WRITE     1
%define POLL      7
%define IOCTL     16
%define NANOSLEEP 35
%define EXIT      60

%macro SYS 1
	mov rax, %1
	syscall
	test rax, rax
	js syscall_err
%endmacro

section .data

sleep_tv:
	.sec  dq 0
	.usec dq 0

section .text

global sleep

; rax: seconds
; rdx: nanoseconds
sleep:
	push rdi
	push rsi

	mov qword [sleep_tv.sec], rax
	mov qword [sleep_tv.usec], rdx
	mov rdi, sleep_tv ; timespec struct
	mov rsi, 0        ; don't store remaining time
	SYS NANOSLEEP

	pop rsi
	pop rdi
	ret

global ioctl

%define TCGETS 21505 ; attr to get struct
%define TCPUTS 21506 ; attr to put struct

; rax - termios struct pointer
; rdx - 0: get, 1: put
ioctl:
	push rdi
	push rsi

	add rdx, TCGETS
	mov rsi, rdx
	mov rdx, rax
	mov rdi, 0
	SYS IOCTL

	pop rsi
	pop rdi
	ret

global exit

; rax: exit code
exit:
	mov rdi, rax
	mov rax, EXIT
	syscall

	; this part must never execute,
	; but still...
	ret

section .data

; poll function struct arg
poll_fd:
	dd STDIN ; fd
	dw 1     ; events
	dw 0     ; revents

section .text

global poll

; rax: buffer
; rdx; count
poll:
	push rdi
	push rsi

	push rax ; save buffer
	push rdx ; save count

	; poll event
	mov rdi, poll_fd ; pointer to struct
	mov rsi, 1       ; only 1 fd - stdin
	mov rdx, 0       ; timeout
	SYS POLL

	mov rsi, rax
	pop rdx ; restore count
	pop rax ; restore buffer

	test rsi, rsi ; test if no event
	jz .no_event

	; read input
	call read

	jmp .exit

	.no_event:
		mov byte [rax], -1

	.exit:
		pop rsi
		pop rdi
		ret

global write

; rax: pointer to string
; rdx: string length
; rcx: fd
write:
	push rdi
	push rsi

	mov rsi, rax ; string pointer
	mov rdi, rcx ; fd
	SYS WRITE

	pop rsi
	pop rdi
	ret

global read

; rax: buffer
; rdx: count
read:
	push rdi
	push rsi

	mov rsi, rax
	mov rdi, STDIN

	.loop:
		SYS READ

		; exit if EOF
		test rax, rax
		je .exit

		; exit if read as many bytes as requested
		cmp rax, rdx
		je .exit

		; read less then requested, repeat syscall
		sub rdx, rax
		jmp .loop

	.exit:
		pop rsi
		pop rdi
		ret

section .data

DEF_STR_DATA text_syscall_err, "System call failed!", 10

section .text

syscall_err:
	mov rax, text_syscall_err
	mov rdx, text_syscall_err_len
	mov rcx, STDERR
	call write
	call exit

; vim:ft=nasm
