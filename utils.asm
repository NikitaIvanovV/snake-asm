section .text

global memcpy
global rand

; rax: destination
; rdx: source
; rcx: size
memcpy:
	mov rsi, rdx
	mov rdi, rax

	cld ; increment in rep

	; copy [rsi] to [rdi]
	; increment rsi and rdi
	; repeat rcx times
	rep movsb

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
