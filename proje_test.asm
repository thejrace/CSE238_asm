TITLE      (.asm)

Include Irvine32.inc

draw_pipes PROTO,
			lpipe:PTR WORD,
			rpipe:PTR WORD,
			row:BYTE
draw_horizontal_line PROTO,
			llength:DWORD

.data
		
	valid_inputs 		BYTE 	'0','1','2','3','4','5','6','7','8','9'
	hline 				WORD   	205
	vline   			WORD   	186
	pipe_tl  			WORD   	201
	pipe_tr  			WORD   	187
	pipe_bl  			WORD   	200
	pipe_br  			WORD   	188
	pipe_t   			WORD   	203
	pipe_b   			WORD   	202
	space 				BYTE    20h,0
	header_tries 		BYTE 	"Tries :",0
	header_title 		BYTE 	"=======< #CRACK THE CODE >=======",0 
	header_output    	BYTE 	"Output:",0
	msg_reentry 		BYTE	"You've already tried this combination!",0
	winmsg				BYTE 	"CRACKED IT!!",0
	winsum 				BYTE    "You've cracked the code with only ",0
	winsum2   			BYTE    " tries!",0
	winsum3 			BYTE    "Try again? ( y / n )", 0
	user_inputs 		BYTE    120 dup (10)
	input_push_counter  DWORD   0
	code 				BYTE    4 dup(10)
	res_plus            BYTE	0
	res_minus 			BYTE    0
	tries 				BYTE    0
	tries_flag          BYTE    0

.code
main PROC
	start:
		; debug codes can be found at
		; comment out lines at 160 and 303 to disable the debugging
		call clrscr
		call start_animation
		call draw_theme
		call get_the_code
		call start_game
	exit
main ENDP

start_animation PROC

	mov eax, 1110b
	call SetTextColor
	
	mov dh, 1
	mov dl, 16
	
	mov esi,0
	mov ecx, 33
	mov ebx, 20
	header_anim:
		call gotoxy
		mov al, header_title[esi]
		call writechar
		inc esi
		inc dl
		mov eax, ebx
		call delay
	loop header_anim

	mov eax, 1111b
	call SetTextColor

	ret
start_animation ENDP

win_animation PROC

	call clrscr

	mov dl, 35
	mov dh, 2
	call gotoxy
	mov edx, offset winmsg
	call writestring

	mov dl, 20
	mov dh, 4
	call gotoxy
	mov edx, offset winsum
	call writestring

	movzx eax, tries
	call writedec

	mov edx, offset winsum2
	call writestring

	mov dl, 20
	mov dh, 5
	call gotoxy
	mov edx, offset winsum3
	call writestring

	
	ret
win_animation ENDP

get_the_code PROC
		
	mov ebx, 0
	random_loop:
		
		call randomize
		mov eax, 10									; reset tokenizer
		call randomrange

		cmp ebx, 0
		jne not_first 								; check same random vals only after first int

		mov code[ebx], al 							; directly push int val
		inc ebx 									; inc index to get second 
		jmp random_loop 							; start over again

		not_first: 							
			
			mov ecx, ebx 							; dont change the ebx just copy it to ecx
			
			prev_check:
				cmp ecx, 0 					
				jl prev_loop_ok 					; loop is decending simply normal for loop in asm
				
				cmp al, code[ecx-1] 				; check previous indexes value with random int
				je random_loop 						; if it exists in the prev indexes, randomize again, we start over

				dec ecx 							; if we reach this line it means current loop index is not same, so it is ok
				jmp prev_check 						; we're gonna check the previous one

			prev_loop_ok:
				mov code[ebx], al           		; previous checks are ok
				inc ebx 							; inc ebx to get correct index

		cmp ebx, 4 									; we need only 4 different digit so we check if all is ok
		je code_ok 									; all okey break the loop
	
		jmp random_loop 							; we need more digits so we create it
	
	code_ok: 										; we're done
		call code_test

	ret
get_the_code ENDP

code_test PROC										; shows the code on top left for debugging
	
	mov dl, 2
	mov dh, 2
	call gotoxy

	mov al, code[0]
	call writedec

	mov al, code[1]
	call writedec

	mov al, code[2]
	call writedec

	mov al, code[3]
	call writedec

	ret
code_test ENDP

user_inputs_test PROC 								; shows the user inputs on top right for debugging
	
	push edx 										; push-pop everything just in case
	push eax
	push ebx
	push edi
	push esi

	mov dh, 3
	mov dl, 65

	mov ecx, input_push_counter
	mov esi, 0
	mov edi, 0
	print_loop:
		call gotoxy
		mov eax,0
		mov al, user_inputs[esi]
		call writedec
		inc esi
		inc edi

		cmp edi, 4
		je edi_reset
		jmp normal_finish
		edi_reset:
			mov edi,0
			inc dh
			mov dl, 64

		normal_finish:
			inc dl

	loop print_loop
	
	pop esi
	pop edi
	pop ebx
	pop eax
	pop edx

	ret
user_inputs_test ENDP

start_game PROC
	game_action:

		mov tries_flag, 0 							; reset everything on a new try
		mov res_minus, 0 							; output minus
		mov res_plus, 0  							; output plus

		mov ecx, 4									; loop limit ( number of inputs )
		mov eax, 0 									; clear read/write char
		mov edi, 0 									; input index

		mov dh, 4 									; set cursor to first input box
		mov dl, 26	

		input_loop:

			call gotoxy
			mov ebx, ecx ; save ecx
			call readchar
			call writechar
			mov ecx, 10
			mov esi, 0
			check_loop:
				cmp al, valid_inputs[esi]
				je input_ok
				inc esi
			loop check_loop

			call buzzer
			mov ecx, ebx 							; dont reset keep the previous entered valid inputs
			jmp input_loop

			input_ok:
				
				inc edi
				mov eax, esi

				push ebx

				mov ebx, input_push_counter 
				mov user_inputs[ebx], al 			; add single input val to inputs array
				inc ebx
				mov input_push_counter, ebx

				pop ebx
				 									; esi contains the input value
				mov ecx, 1 							; edi is 1 indexed, in order to get compare with edi, start from 1
				result_loop:
					cmp al, code[ecx-1] 			; check input
					jne std_action

					pos_check:  					; if code contains input, check the position for plus and minus counter
						cmp edi, ecx
						jne dec_minus

					inc_plus:
						inc res_plus
						jmp std_action

					dec_minus:
						inc res_minus

					std_action: 					; loop 0 to 4, not like std loop in asm
						
						inc ecx
						cmp ecx, 5

						jne result_loop
				
				add dl, 4
				mov ecx, ebx
		loop input_loop

		call user_inputs_test

		all_inputs_ok:

			movzx ecx, tries 						; outer loop limit
			mov edx, 0 								; old entries array index it won't be resetted, inc all the time
		
			tries_loop:	 							; compare last input with previous ones

				mov ebx, input_push_counter    		; last input's 0 array index ( we do this here because it needs to be resetted )
				cmp ebx, 4
				je start_no_check 			   		; no need to check for first input

				push ecx
				mov edi,0 							; no match flag

				sub ebx, 4 							
				;call dumpregs
				
				mov ecx, 4
				

				reentry_loop:
					mov al, user_inputs[edx]
					cmp al, user_inputs[ebx] 		; compare old[x] with last[x]
					jne re_no_match

					inc edx 
					inc ebx 						
					jmp normal_end

					re_no_match: 
						add edx, ecx 				; if there was no match, completely skip the old input set, jump to next one
						jmp break_re_loop 			; skip the current input set loop

					normal_end:

				loop reentry_loop	

				inc edi 							; if we reached to this point then we have a full match
				pop ecx 							; we jump break_re_loop so we have to pop ecx to not mess with ret adress, ebp etc.
				jmp final_match_check
				
				break_re_loop:
					pop ecx 						; retrieve outer loop counter

			loop tries_loop

			final_match_check:

				cmp edi, 0 							; check match flag
				je not_same_input

				same_input_entered:

					mov dh, 8 						; display a message ( clear this message at every game_action start )
					mov dl, 20
					call gotoxy
					mov edx, offset msg_reentry
					call writestring 				

					call buzzer

					sub input_push_counter, 4 		; overwrite the last input to sync it with tries

					mov eax, 1000
					call delay

					mov dh, 8 						; display a message ( clear this message at every game_action start )
					mov dl, 20
					mov ecx, 38
					remsg_clear_loop:
						call gotoxy
						mov al, space
						call writechar
						inc dl
					loop remsg_clear_loop

					mov tries_flag, 1 				; set no inc tries flag

				not_same_input:

			start_no_check:  						; we jump here when user entered first input ( skip the reentry check loop )

			mov dh, 3
			mov dl, 55
			call gotoxy
			
			cmp tries_flag, 0 						; tries inc conditions..
			jne skip_tries_inc
			inc tries
			skip_tries_inc:	

			movzx eax, tries 						; print it
			call writedec
				
			mov dh, 5
			mov dl, 57
			call gotoxy

			mov ecx, 4 								; clear input boxes
			clear_loop:
				call gotoxy
				push edx
				mov edx, offset space
				call writestring
				pop edx
				inc dl
			loop clear_loop
			
			mov dh, 5 								; output printing actions
			mov dl, 55
			call gotoxy

			cmp res_plus, 0
			je skip_plus

			cmp res_plus, 4
			je win

			mov al, res_plus
			call writeint

			skip_plus:

			cmp res_minus, 0
			je skip_minus

			mov al, '-'
			call writechar
			
			mov al, res_minus
			call writedec

			skip_minus:

				mov eax, 500
				call delay
				call clear_inputs
				jmp game_action 					; start over

			win:

				call win_animation
				call readchar
				cmp al, 'y'

				mov res_minus, 0
				mov res_plus, 0
				mov input_push_counter, 0			; reset with tries, to overwrite user_inputs values
				mov tries, 0

				je main 							; reset the program

	ret
start_game ENDP

clear_inputs PROC
	
	mov dh, 4
	mov dl, 26
	mov ecx,4
	clear_loop:
		call gotoxy
		push edx
		mov edx, offset space
		call writestring
		pop edx
		add dl,4
	loop clear_loop
	
	ret
clear_inputs ENDP

buzzer PROC 
	mov al,7
	call writechar
	ret
buzzer ENDP

draw_theme PROC
	
	mov dl, 20  									; init first x, y [20, 2]
	mov dh, 2
	invoke draw_horizontal_line, 25	    			; draw top horizontal

	invoke draw_pipes, ADDR pipe_tl, ADDR pipe_tr, 2
	
	call draw_vertical_line 						; draw vertical lines for left and right

	mov dl, 20  									; init last row coords 
	mov dh, 6
	invoke draw_horizontal_line, 25	    			; draw bottom horizontal		

	invoke draw_pipes, ADDR pipe_bl, ADDR pipe_br, 6

	; spaces start
	mov dh, 4
	mov dl, 28
	call gotoxy

	mov edx, offset vline
	call writestring

	mov dh, 4
	mov dl, 28
	call gotoxy

	mov edx, offset vline
	call writestring

	mov dh, 4
	mov dl, 32
	call gotoxy

	mov edx, offset vline
	call writestring

	mov dh, 4
	mov dl, 36
	call gotoxy

	mov edx, offset vline
	call writestring
	; spaces end


	; pipes left
	mov dh, 3
	mov dl, 24
	call gotoxy

	mov edx, offset pipe_tl
	call writestring

	mov dh, 4
	mov dl, 24
	call gotoxy

	mov edx, offset vline
	call writestring

	mov dh, 5
	mov dl, 24
	call gotoxy

	mov edx, offset pipe_bl
	call writestring

	mov dl, 25
	mov dh, 3
	invoke draw_horizontal_line, 16

	; pipes left end


	; pipes right
	mov dh, 3
	mov dl, 40
	call gotoxy

	mov edx, offset pipe_tr
	call writestring

	mov dh, 4
	mov dl, 40
	call gotoxy

	mov edx, offset vline
	call writestring

	mov dh, 5
	mov dl, 40
	call gotoxy

	mov edx, offset pipe_br
	call writestring

	mov dl, 25
	mov dh, 5
	invoke draw_horizontal_line, 15

	; pipes right end

	; spaces top connections
	mov dh, 3
	mov dl, 28
	call gotoxy

	mov edx, offset pipe_t
	call writestring

	mov dh, 3
	mov dl, 32
	call gotoxy

	mov edx, offset pipe_t
	call writestring
	
	mov dh, 3
	mov dl, 36
	call gotoxy

	mov edx, offset pipe_t
	call writestring

	mov dh, 5
	mov dl, 28
	call gotoxy

	mov edx, offset pipe_b
	call writestring

	mov dh, 5
	mov dl, 32
	call gotoxy

	mov edx, offset pipe_b
	call writestring

	mov dh, 5
	mov dl, 36
	call gotoxy

	mov edx, offset pipe_b
	call writestring

	; spaces top connections end

	mov dh, 3
	mov dl, 47
	call gotoxy

	mov edx, offset header_tries
	call writestring

	mov dh, 5
	mov dl, 47
	call gotoxy

	mov edx, offset header_output
	call writestring



	ret
draw_theme ENDP

draw_pipes PROC lpipe:PTR WORD, rpipe:PTR WORD, row:BYTE

	mov dl, 19  								; gotoxy( 20, 2/18 )
	mov dh, row
	call gotoxy

	mov edx, lpipe  							; draw cross pipe left side
	call writestring

	mov dl, 45  								; gotoxy( 45, 2/18 )
	mov dh, row
	call gotoxy

	mov edx, rpipe 								; draw crospipe right side
	call writestring
	
	ret
draw_pipes ENDP	

draw_vertical_line PROC
	
	mov dl, 19									; gotoxy( 20, 3 ) next row start
	mov dh, 3
	mov ecx, 4									; height: 15 lines
	draw_loop:

		mov bl, dl 								; save the cursor values using ebx register
		mov bh, dh
		call gotoxy								; gotoxy( 20, 3 ) --> gotoxy( 20, 4 ) ...

		mov edx, offset vline           		; draw vertical line to start
		call writestring

		mov dl, 45
		mov dh, bh
		call gotoxy 							; gotoxy( 45, 3 ) --> gotoxy( 45, 4 ) ....

		mov edx, offset vline           		; draw vertical line to end
		call writestring

		inc bh 									; go to next row
		mov dh, bh  							; retrieve the x, y 
		mov dl, 19

	loop draw_loop
	
	ret
draw_vertical_line ENDP

draw_horizontal_line PROC llength:DWORD

	mov ecx, llength							; width					
	draw_loop:

		call gotoxy 							; gotoxy( 20, 2 ) --> gotoxy( 21, 2 ) ...

		mov bl, dl  							; save the x, y
		mov bh, dh

		mov edx, offset hline  					; draw horizontal line
		call writestring

		mov dh, bh 								; retrieve the x,y
		mov dl, bl
		inc dl 									; goto next col

	loop draw_loop

	
	ret
draw_horizontal_line ENDP

END main