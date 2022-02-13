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
	mov rcx, rax ; store upper limit

	rdrand rax ; store random number

	mov rdx, 0
	div rcx ; rdx now stores the remainder

	mov rax, rdx ; ret in rax
	ret

; vim:ft=nasm
