section .text

global memcpy
global rand

; rax: destination
; rbx: source
; rcx: size
memcpy:
	push rcx
	push rdx

	memcpy_loop:
		dec rcx

		mov rdx, [rbx+rcx]
		mov [rax+rcx], rdx

		cmp rcx, 0
		jne memcpy_loop

	pop rdx
	pop rcx
	ret

; rax: upper limit
; returns: random num in rax
rand:
	push rbx
	push rdx

	mov rbx, rax ; store upper limit

	rdrand rax ; store random number

	mov rdx, 0
	div rbx ; rdx now stores the remainder

	mov rax, rdx ; ret in rax

	pop rdx
	pop rbx
	ret

section .data

sleep_tv:
	sleep_tv_sec  dq 0
	sleep_tv_usec dq 0

section .text

global sleep

; rax: seconds
; rbx: nanoseconds
sleep:
	push rdi
	push rsi

	mov qword [sleep_tv_sec], rax
	mov qword [sleep_tv_usec], rbx
	mov rax, 35 ; system call nanosleep
	mov rdi, sleep_tv
	xor rsi, 0
	syscall

	pop rsi
	pop rsi
	ret

; vim:ft=nasm
