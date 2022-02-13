%include "syscall.mac"

%define ICANON (1<<1)
%define ECHO   (1<<3)

section .bss

; termios structs
stty resb termios_s_size
tty  resb termios_s_size

section .text

global set_noncanon

set_noncanon:
	; store old termios
	mov rax, stty
	mov rdx, 0
	call ioctl

	; store termios
	mov rax, tty
	mov rdx, 0
	call ioctl

	; remove icanon and echo flags
	and dword [tty+termios_s.flags], (~ICANON)
	and dword [tty+termios_s.flags], (~ECHO)

	; set attrs
	mov rax, tty
	mov rdx, 1
	call ioctl
	ret

global set_canon

set_canon:
	; restore from saved termios struct
	mov rax, stty
	mov rdx, 1
	call ioctl
	ret

; vim:ft=nasm
