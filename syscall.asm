%define SYSCALL_READ      0
%define SYSCALL_WRITE     1
%define SYSCALL_POLL      7
%define SYSCALL_IOCTL     16
%define SYSCALL_NANOSLEEP 35
%define SYSCALL_EXIT      60

%define STDIN  0
%define STDOUT 1

section .data

sleep_tv:
	sleep_tv_sec  dq 0
	sleep_tv_usec dq 0

section .text

global sleep

; rax: seconds
; rdx: nanoseconds
sleep:
	push rdi
	push rsi

	mov qword [sleep_tv_sec], rax
	mov qword [sleep_tv_usec], rdx
	mov rax, SYSCALL_NANOSLEEP
	mov rdi, sleep_tv
	xor rsi, 0
	syscall

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
	mov rax, SYSCALL_IOCTL
	mov rdi, 0
	syscall

	pop rsi
	pop rdi
	ret

global exit

; rax: exit code
exit:
	mov rdi, rax
	mov rax, SYSCALL_EXIT
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

; rax: address to save input to
poll:
	push rdi
	push rsi

	push rax ; save input addr

	; poll event
	mov rax, SYSCALL_POLL
	mov rdi, poll_fd ; pointer to struct
	mov rsi, 1       ; only 1 fd - stdin
	mov rdx, 0       ; timeout
	syscall

	mov rsi, rax
	pop rax ; restore input addr

	test rsi, rsi ; test if no event
	jz poll_no_event

	; read input
	mov rdx, 1
	call read

	jmp poll_exit

	poll_no_event:
		mov byte [rax], 0

	poll_exit:
		pop rsi
		pop rdi
		ret

global write

; rax: pointer to string
; rdx: string length
write:
	push rdi
	push rsi

	mov rsi, rax    ; string pointer
	mov rax, SYSCALL_WRITE
	mov rdi, STDOUT ; fd stdout
	syscall

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
	mov rax, SYSCALL_READ
	mov rdi, STDIN
	syscall

	pop rsi
	pop rdi
	ret

; vim:ft=nasm
