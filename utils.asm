%include "syscall.mac"

section .text

global memcpy
global rand

; rax: destination
; rdx: source
; rcx: size
memcpy:
	dec rcx

	mov r8, [rdx+rcx]
	mov [rax+rcx], r8

	cmp rcx, 0
	jne memcpy
	ret

; rax: upper limit
; returns: random num in rax
rand:
	mov r12, rax ; store upper limit

	rdrand rax ; store random number

	mov rdx, 0
	div r12 ; rdx now stores the remainder

	mov rax, rdx ; ret in rax
	ret

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

; vim:ft=nasm
