TITLE      (.asm)

; Obarey

Include Irvine32.inc
.data
	msg1		byte 	"Enter a string( max 100 chars ): ",0
	msg2		byte	"Enter what you are looking for( max 10 chars ): ",0
	buffer_str  byte 	100 dup(0),0 ; @buffer -> string to be searched
	buffer_kw	byte	10  dup(0),0 ; @buffer -> keyword
	res			byte 	0
	stars		byte    100 dup(20h) ; filled with spaces
.code
main PROC
	
	call clrscr

	mov edx, offset msg1
	call writestring

	mov edx, offset buffer_str
	mov ecx, lengthof buffer_str-1 
	call readstring	 				; read search string
	push eax						; save string length for loop

	mov edx, offset msg2
	call writestring

	mov edx, offset buffer_kw 
	mov ecx, lengthof buffer_kw-1
	call readstring					; read keyword string

	mov edx, eax					; keyword string length
	pop eax
	mov ecx, eax					; string length
	mov esi, 0						; string index
	mov edi, 0						; keyword index
	mov eax, 0

	str_loop:
		push esi					; save string index 
		kw_loop:
			mov al, buffer_kw[edi]
			cmp al, buffer_str[esi]
			jne kw_break			; no match, break the kw loop
			inc esi
			inc edi
			cmp edi, edx			; check if all chars in keyword looped through
			je kw_found
			jmp kw_loop				; else we continue to check and compare
		
		kw_found:
			inc res
			push ecx
			mov ecx, edx
			star:
				mov stars[esi-1], '*'
				dec esi
				loop star
			pop ecx

		kw_break:
			pop esi					; restore string index
			inc esi					; increment it
			mov edi, 0 				; reset kw index

	loop str_loop

	call crlf

	mov edx, offset buffer_str
	call writestring

	call crlf

	mov edx, offset stars
	call writestring

	;movzx eax, res
	;call writeint

	exit
main ENDP

END main