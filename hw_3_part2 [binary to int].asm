TITLE (.asm)

Include Irvine32.inc

.data
	msg1 			BYTE "Enter a binary value: ",0
	msg2 			BYTE "You've entered an invalid binary value!",0
	msg3 			BYTE "Try again?(y/n): ", 0
	input_buffer 	BYTE 32 dup(0),0
	sign_buffer 	BYTE 2Bh,0
.code

main PROC

	call bintoint
	
	exit
main ENDP

bintoint PROC
	start:
		mov sign_buffer[0], 2Bh						; reset sign for try again
		mov edx, offset msg1
		call writestring
		mov edx, offset input_buffer
		mov ecx, lengthof input_buffer-1 
		call readstring	 							; read as string ( length in eax )
		mov ecx, eax
		mov esi, 0 ; index
		mov ebx, 0 									; result
		mov edi, 1 									; pow index
		convert_loop:
			cmp input_buffer[esi], 31h 				; check if 1
			je sum_action
			cmp input_buffer[esi], 30h 				; check if 0
			je zero_action
			jmp invalid_input
			sum_action:
				cmp esi, 0
				je sign_str_init 					; if leftmost bit is 1, init minus sign
				cmp esi, lengthof input_buffer-1 	; rightmost bit is 1, add 1 to result ( due to 2^0 )
				je last_bit
				mov eax, ecx 						; calculation of 1 bits between first and last bit
				dec eax 							; for example: 4th bit -> 2*2*2  
				sum_loop:
					cmp eax, 0	
					je cont 						; eax 0, break 
					imul edi, 2 					; calculate the power
					dec eax
				jmp sum_loop
				cont:
					add ebx, edi  					; add sum to the result
					mov edi, 1    					; reset the pow index
				jmp zero_action   					; jump to the end
				sign_str_init:
					mov sign_buffer[0], 2Dh  		; init the - sign
					jmp zero_action
				last_bit: 
					inc ebx  						; ebx += 2^0
				zero_action:
					inc esi  						; increment input index
		loop convert_loop
		jmp no_error_finish 						; if code made it this far, means no error, we jump over invalid_input
		invalid_input:
			mov edx, offset msg2 					; show error message
			call writestring
			jmp finish 								; jump to mainend
		no_error_finish:
			mov edx, offset sign_buffer 			; print sign 
			call writestring
			mov eax, ebx 			
			call writedec							; print result
		finish:
			call crlf
			mov edx, offset msg3
			call writestring
			mov edx, offset input_buffer
			mov ecx, lengthof input_buffer-1 
			call readstring	 						; read response
			cmp input_buffer[0], 79h				; y
			je start

	ret
bintoint ENDP

END main