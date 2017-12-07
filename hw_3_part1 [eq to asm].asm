TITLE (.asm)

Include Irvine32.inc

.data

	

.code

main PROC
		
	; test parameters
	mov cx, 100
	mov esi, 20
	mov edi, 100
	mov ax, 16
	mov bx, 16

	;call dumpregs

	imul ax, bx
	mov dx,ax 						; save result for downside (ax*bx)
	;call dumpregs

	push dx
	cwd								; extend ax to dxax
	;call dumpregs

	push cx
	mov cx, 2
	idiv cx  						; ax = (ax*bx/2)
	;call dumpregs

	pop cx
	pop dx

	imul cx, si
	push ax
	push dx
	mov ax,cx
	cwd 							; extend ax to dxax
	mov bx, 4
	idiv bx
	mov bx, ax 						; bx = (cx*si)/4

	pop dx
	pop ax

	add ax, bx 						; [(ax*bx/2) + (cx*si/4)]

	push ax
	push dx

	mov eax, edi
	cdq 							; extend eax to edx:eax
	idiv esi 						; eax = (edi/esi)
	mov edi, eax

	;call dumpregs

	pop dx
	pop ax

	movsx ebx, dx 
	add edi, ebx  					; edi = [(ax*bx) + (edi/esi)]

	movsx eax, ax 					; extend ax
	cdq 							; eax to edx:eax
	idiv edi 						; eax = [(ax*bx/2) + (cx*si/4)] / [(ax*bx) + (edi/esi)]

	;call dumpregs


	exit
main ENDP
END main