%include "print.mac"
%include "syscall.mac"

%define MAIN _start

%define MOVE_EVERY_TICK   2
%define SIZE_X            21
%define SIZE_Y            21
%define EATEN_APPLES_INIT 3
%define UPD_DEL_SEC       0
%define UPD_DEL_NANO      50000000

%assign SIZE_N SIZE_X*SIZE_Y
%assign SNAKE_X_INIT SIZE_X/2
%assign SNAKE_Y_INIT SIZE_Y/2

%define DIR_UP    0
%define DIR_RIGHT 1
%define DIR_DOWN  2
%define DIR_LEFT  3

%define MAP_FREE  0
%define MAP_WALL  1
%define MAP_HEAD  2
%define MAP_BODY  3
%define MAP_APPLE 4

%define STATUS_RUN  0
%define STATUS_EXIT 1
%define STATUS_DIE  2

%define CELL_TEXT '  '
%strlen CELL_TEXT_LEN CELL_TEXT

%macro DEF_ESC_SEQ 3+
	DEF_STR_DATA %1, 27, '[', %3, %2
%endmacro

%macro DEF_COLOR_SEQ 3
	DEF_ESC_SEQ color_%1_seq, 'm', '1', ';', %2, ';', %3
%endmacro

%macro MAP_BUFFER 1
	%1:
		times SIZE_X db MAP_WALL ; top wall
		%rep SIZE_Y-2 ; cells between top and bottom walls
			db MAP_WALL ; left wall
			times SIZE_X-2 db MAP_FREE ; free space
			db MAP_WALL ; right wall
		%endrep
		times SIZE_X db MAP_WALL ; bottom wall
%endmacro

%define ESC_SEQ_MAX_LEN 10

%assign MAX_CELL_PRINT_SIZE ESC_SEQ_MAX_LEN*2+CELL_TEXT_LEN

%macro PRINT_BUFFER 1
	%1 resb SIZE_N*MAX_CELL_PRINT_SIZE
%endmacro

section .data

%assign SCREEN_Y SIZE_Y+1
%defstr SCREEN_Y_STR SCREEN_Y

; ANSI escape seqences
DEF_ESC_SEQ cur_reset_seq, 'A', SCREEN_Y_STR
DEF_ESC_SEQ cur_home_seq, 'H', '0', ';', '0'
DEF_ESC_SEQ cur_hide_seq, 'l', '?', '25'
DEF_ESC_SEQ cur_show_seq, 'h', '?', '25'
DEF_ESC_SEQ clear_seq, 'J', '0'
DEF_ESC_SEQ color_reset_seq, 'm', '0'
DEF_COLOR_SEQ bright_red, '91', '101'
DEF_COLOR_SEQ blue, '34', '44'
DEF_COLOR_SEQ yellow, '33', '43'
DEF_COLOR_SEQ bright_yellow, '93', '103'

; Strings
DEF_STR_DATA text_score, "Score: "
DEF_STR_DATA text_controls, "Move: wasd  Quit: q", 10
DEF_STR_DATA text_game_over, "GAME OVER!", 10
DEF_STR_DATA cell_sym, CELL_TEXT

; Some global vars
status db STATUS_RUN

MAP_BUFFER map

length dq 1
score dq 0
eaten dq EATEN_APPLES_INIT
snake_x dq SNAKE_X_INIT
snake_y dq SNAKE_Y_INIT

input db 0
frame dq 0

; dir in which snake will move
move_dir db DIR_RIGHT
future_move_dir db DIR_RIGHT

section .bss

; buf to store free map cells for get_free_cells
map_free_buf resq SIZE_N
map_free_buf_len resq 1

PRINT_BUFFER print_buf
print_buf_len resq 1

snake_cells_buf resq SIZE_N

section .text

global MAIN

extern memcpy
extern rand
extern set_noncanon
extern set_canon

; rax: x
; rdx: y
; returns: map index in rax
map_coord_to_index:
	imul rdx, SIZE_X
	add rax, rdx
	ret

%macro HANDLE_KEY 2
	cmp byte [input], %2
	je .%1
%endmacro

handle_key:
	; old move dir
	mov al, [move_dir]

	HANDLE_KEY quit,  'q'
	HANDLE_KEY right, 'd'
	HANDLE_KEY down,  's'
	HANDLE_KEY left,  'a'
	HANDLE_KEY up,    'w'

	jmp .exit

	.quit:
		mov byte [status], STATUS_EXIT
		jmp .exit

	.right:
		cmp al, DIR_LEFT
		je .exit
		mov byte [future_move_dir], DIR_RIGHT
		jmp .exit

	.down:
		cmp al, DIR_UP
		je .exit
		mov byte [future_move_dir], DIR_DOWN
		jmp .exit

	.left:
		cmp al, DIR_RIGHT
		je .exit
		mov byte [future_move_dir], DIR_LEFT
		jmp .exit

	.up:
		cmp al, DIR_DOWN
		je .exit
		mov byte [future_move_dir], DIR_UP
		jmp .exit

	.exit:
		ret

%macro PRINT_BUF_APPEND 1
	mov rax, print_buf
	add rax, [print_buf_len]
	mov rdx, %1
	mov rcx, %1_len
	add [print_buf_len], rcx
	call memcpy
%endmacro

%macro DRAW_CELL 0
	PRINT_BUF_APPEND cell_sym
%endmacro

%macro DRAW_COLOR_CELL 1
	PRINT_BUF_APPEND color_%1_seq
	DRAW_CELL
	PRINT_BUF_APPEND color_reset_seq
%endmacro

print_term_buf:
	mov rax, print_buf
	mov rdx, [print_buf_len]
	call print
	mov qword [print_buf_len], 0
	ret

; rax: cell
draw_cell:
	cmp rax, MAP_WALL
	je .wall

	cmp rax, MAP_HEAD
	je .head

	cmp rax, MAP_BODY
	je .body

	cmp rax, MAP_APPLE
	je .apple

	jmp .free

	.free:
		DRAW_CELL
		jmp .exit

	.wall:
		DRAW_COLOR_CELL blue
		jmp .exit

	.head:
		DRAW_COLOR_CELL yellow
		jmp .exit

	.body:
		DRAW_COLOR_CELL bright_yellow
		jmp .exit

	.apple:
		DRAW_COLOR_CELL bright_red
		jmp .exit

	.exit:
		ret

draw_map:
	push rbx
	push r11

	mov bh, 0  ; x counter
	mov bl, 0  ; y counter
	mov r11, 0 ; map cell

	.loop_y:
		.loop_x:
			mov rax, 0
			mov al, [map+r11]
			call draw_cell

			inc r11

			inc bh
			cmp bh, SIZE_X
			jne .loop_x

		PRINT_BUF_APPEND newline

		mov bh, 0

		inc bl
		cmp bl, SIZE_Y
		jne .loop_y

	PRINT_BUF_APPEND text_score

	call print_term_buf

	mov rax, [score]
	call print_num
	PRINT_NEW_LINE

	pop r11
	pop rbx
	ret

clear_screen:
	PRINT_BUF_APPEND cur_reset_seq
	ret

move_snake:
	mov al, [future_move_dir]
	mov [move_dir], al

	cmp al, DIR_RIGHT
	je .rigth

	cmp al, DIR_DOWN
	je .down

	cmp al, DIR_LEFT
	je .left

	cmp al, DIR_UP
	je .up

	.rigth:
		inc qword [snake_x]
		jmp .exit

	.down:
		inc qword [snake_y]
		jmp .exit

	.left:
		dec qword [snake_x]
		jmp .exit

	.up:
		dec qword [snake_y]
		jmp .exit

	.exit:
		mov rax, [snake_x]
		mov rdx, [snake_y]
		call map_coord_to_index ; rax: map index of old head
		call update_state
		call update_map_snake

		ret

update_map_snake:
	mov rcx, [length]

	; save tail position
	push qword [snake_cells_buf+rcx*8-8]

	.loop:
		dec rcx
		cmp rcx, 0
		jle .loop_exit

		; shift data in the array, so 1st cell becomes 2nd,
		; 2nd becomes 3rd, etc...
		mov rax, [snake_cells_buf+rcx*8-8]
		mov [snake_cells_buf+rcx*8], rax

		; set map cell
		mov byte [map+rax], MAP_BODY

		jmp .loop

	.loop_exit:
		mov rcx, [length]

		mov rax, [snake_x]
		mov rdx, [snake_y]
		call map_coord_to_index

		; set new head position
		mov [snake_cells_buf], rax
		mov byte [map+rax], MAP_HEAD

		; restore tail position
		pop rax

		; check if snake needs to grow
		cmp qword [eaten], 0
		jg .grow

		; free old tail cell if it was not replaced with anything
		cmp byte [map+rax], MAP_BODY
		jne .exit
		mov byte [map+rax], MAP_FREE
		jmp .exit

	.grow:
		mov byte [map+rax], al
		mov [snake_cells_buf+rcx*8], rax

		dec qword [eaten]
		inc qword [length]

	.exit:
		ret

; rax: new snake head pos
update_state:
	mov dl, [map+rax]

	cmp dl, MAP_WALL
	je .die

	cmp dl, MAP_HEAD
	je .die

	cmp dl, MAP_BODY
	je .die

	cmp dl, MAP_APPLE
	je .grow

	jmp .exit

	.die:
		mov byte [status], STATUS_DIE
		jmp .exit

	.grow:
		inc qword [eaten]
		inc qword [score]
		call place_apple
		jmp .exit

	.exit:
		ret

update:
	call move_snake
	call clear_screen
	call draw_map

	inc qword [frame]

	ret

get_free_cells:
	mov rcx, 0 ; counter
	mov [map_free_buf_len], rcx

	.loop:
		cmp byte [map+rcx], MAP_FREE
		jne .loop_inc

		mov rax, [map_free_buf_len]
		mov [map_free_buf+rax*8], rcx
		inc qword [map_free_buf_len]

	.loop_inc:
		inc rcx
		cmp rcx, SIZE_N
		jne .loop

	ret

place_apple:
	call get_free_cells

	; amount of free cells
	mov rax, [map_free_buf_len]

	cmp rax, 0
	je .exit

	; stores rand num from 0 to rax in rax
	call rand

	mov rdx, [map_free_buf+rax*8]

	mov byte [map+rdx], MAP_APPLE

	.exit:
		ret

run:
	push rbx

	; update count
	mov rbx, 0

	.loop:
		mov rax, input
		call poll

		call handle_key

		cmp byte [status], STATUS_EXIT
		je .exit

		cmp byte [status], STATUS_DIE
		je .die

		cmp rbx, MOVE_EVERY_TICK
		je .update

		inc rbx

		mov rax, UPD_DEL_SEC
		mov rdx, UPD_DEL_NANO
		call sleep

		jmp .loop

	.update:
		call update
		mov rbx, 0
		jmp .loop

	.die:
		PRINT_STR_DATA text_game_over

	.exit:
		pop rbx
		ret

init:
	mov rax, [snake_x]
	mov rdx, [snake_y]
	call map_coord_to_index ;snake pos in rax

	; add snake to map
	mov byte [map+rax], MAP_HEAD

	; init snake_cells_buf
	mov qword [snake_cells_buf], rax

	; add first apple
	call place_apple

	; init print buffer
	mov qword [print_buf_len], 0

	call set_noncanon

	PRINT_BUF_APPEND cur_home_seq
	PRINT_BUF_APPEND clear_seq
	PRINT_BUF_APPEND text_controls
	PRINT_BUF_APPEND cur_hide_seq

	ret

shutdown:
	PRINT_STR_DATA cur_show_seq
	call set_canon
	ret

MAIN:
	call init

	call draw_map

	call run

	call shutdown

	mov rax, 0
	call exit

; vim:ft=nasm
