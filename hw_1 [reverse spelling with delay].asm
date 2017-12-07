TITLE      (.asm)
; This program
; Last update:

Include Irvine32.inc
.data
	msg1	byte 	"Enter a string: ",0
	buffer  byte 	50 dup(0),0
.code
main PROC
	
	call clrscr

	mov edx, offset msg1
	call writeString
	
	mov edx, offset buffer
	mov ecx, lengthof buffer - 1
	call readstring
	mov ecx, eax
	inc ecx
	mov dl,0
	mov dh,1
	call gotoxy
	write_l:
		mov al, buffer[ecx - 1]
		call gotoxy
		call writechar
		mov eax, 500
		call delay
		inc dl
		inc dh
		loop write_l;
	exit
main ENDP
END main