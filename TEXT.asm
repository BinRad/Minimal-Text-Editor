; Minimal Text Editor
code segment
assume CS:code
	org 100h				;leaves room for stuff
start:
jmp realstart
welcome db 40 dup(?),"    The City College of New York", 48 dup(?)
				db " Project 2: Assembly || Professor Vulis ", 40 dup(?)
				db "      Student: Binyamin Radensky        ", 200 dup(?)
				db "   ___ __   ___   __ __  ___ __  __     "
				db "    | |_ \_/ |   |_ |  \| | /  \|__)    "
				db "    | |__/ \ |   |__|__/| | \__/|  \    ", 120 dup(?)
				db "      Press any key to [CONTINUE]       ", 200 dup(?)
				db "         MINIMAL TEXT EDITOR", 290 dup(?)
				db "          to exit use [esc]" , 54 dup(?)
menu_bar db  "  [CTRL+S], [ESC]     ",  "Mode: "
mode db  "OverType               "
ins_mode db "INSERT                "
saved db "SAVE SUCCESFUL"
fname 	db 8 dup(?), 0
handle 	dw ?
error_code db ?,?, "error    "
data 	db 30000 dup(?),0
fsize dw ?
buffer 	db 30000 dup(" "), 0
row db ?
col db ?
page_numb db 0
b db ?
nsize dw ?
;Functions
clearscreen:
	mov di, 0				;to center the text
	mov cx, 2000			;for loop
	mov ah, 0fh				;clears af for clean background
	mov al, " "
	clear:
		mov es:[di], ax			;puts ax into video memory to be displ on screen
		add di, 2
		loop clear
	ret
error:
	mov si, offset error_code
	mov cx, 50
	mov di, 0				;to start at beginning
	mov cx, 8			;for loop
	mov ah, 04fh		;scary lloking colors
	call write_data
	mov ax, 0
	int 16h
	ret
write_data:
	;must set the following:
	;mov si, offset data
	;mov di, 80					;to start at beginning
	;mov cx, 76					;for loop
	mov ax,0B800h			;moves vid into the accu
	mov es, ax  			;moves video mem to es so we can icnrement through it
	mov ah, 71h				; for looks
	print:
	mov al, [si]			;put incrememnted array in to al
	mov es:[di], ax			;puts ax into video memory to be displ on screen
	add si, 1
	add di, 2
	loop print
	ret
	;allows user to put number into board (called at 197)
write_array:
		;add fsize, "0"    ; was using for testing
		mov bl, 71h
		mov si, offset data
		mov cx, fsize					;for loop
		mov di, 80
	write_data1:
		push cx
		mov al, [si]				;put incrememnted array into al
		call insert
		inc si
		pop cx
		loop write_data1
		ret
writemenu:
	mov si, offset menu_bar
	mov di, 0				;to start at beginning
	mov cx, 40				;for loop
	mov ah, 05fh;
	menu_loop:
	mov al, [si]			;put incrememnted array in to al
	mov es:[di], ax			;puts ax into video memory to be displ on screen
	add si, 1
	add di, 2
	loop menu_loop
	ret
enter_key:
	;you have to zero the dx register before you call it
	cmp dx, di					;if bigger thtne its the next line
	jg next_line
		add dx, 80			;is the next lienn the next line
		jmp enter_key
	next_line:
	mov di, dx						;start writing on the next line
 	add si, 1							;skip the 10 after the 13
	ret
insert:
	; al = pressed key
	sub dx, dx
	cmp al, 13
	je enter_key
	mov ah, 71h
	mov es:[di], ax			;puts ax into video memory to be displ on screen
	add di, 2
	ret
	status_selection:
		ret
save_file:
	push di							;so that user can continue writing where left off
	push si
	;actually point to video memory
	mov ax,0B800h			;moves vid into the accu
	mov es, ax  			;moves video mem to es so we can icnrement through it
	mov si, 80
	mov di, offset buffer 	;destination is the array
	mov cx, fsize			;bytes to move
	sub dx, dx				;will be used to put in 13,10 by remembring if 2 spaces
	save_loop:
		mov ax, es:[si]			;move from video memory to data
		cmp al, " "
		jg put_in
			add si, 2
			mov ax, es:[si]			;move from video memory to data
			sub si, 2
			cmp al, " "
			mov al, " "
			jg put_in
				mov byte ptr [di], 13
				add di, 1
				mov byte ptr [di], 10
				add di, 1
				sub bx, bx
				no_space:
				add bx, 1
				add si, 2
				mov ax, es:[si]			;move from video memory to data
				cmp bx, 78
				jge put_in
				cmp al, " "
				jle no_space
		put_in:
		mov [di], al
		add si, 2						;next byte in vid memory
		inc di							;next byte in DATA
		loop save_loop
	pop si

	;first open the file
	push cx
	mov cx, nsize
	mov ah, 3dh				; set fn to open file
	mov al, 02h				;mode
	mov dx, offset fname	;move the file name to the registers
	int 21h					;calls the interrupt to open the file
	mov word ptr handle, ax	;get the handle
	;actual wrte
	mov dx, offset buffer		;where the stuff to be written is currentlyt held in mem
	mov ah, 40h								; mov func for saving the file
	mov bx, word ptr handle		;mov the hand le to bx to be used to write to the file
	mov cx, fsize						;the amunt of bytes to be written
	int 21h										;interrupt to actually to write to the file
	mov word ptr error_code, ax	;
	add error_code, "0"
	jnc No_error5
		call error
		jmp end_of_write
	No_error5:
	mov si, offset error_code
	mov di, 76					;to start at beginning
	mov cx, 1					;for loop
	mov ah, 04fh
	call print
	mov si, offset saved
	mov di, 44					;to start at beginning
	mov cx, 14					;for loop
	mov ah, 2fh
	call print
	end_of_write:
	mov ah, 3eh					;clsoe file
	mov bx, handle
	int 21h
	pop cx
	pop di
	ret

; REAL START ===================================================================
realstart:
	mov ah, 0
	mov al, 00
	int 10h					;video interrupt
	;call set_bkgnd
	mov ax,0B800h			;moves vid into the accu
	mov es, ax  			;moves video mem to es so we can icnrement through it
	mov ah, 3fh;71h			;sets color of output
 ;draw welcome screen------------------------------------------------
	mov si, offset welcome
	mov di, 0				;to start at beginning
	mov cx, 2000				;for loop
writewelc:
	mov al, [si]			;put incrememnted array in to al
	mov es:[di], ax			;puts ax into video memory to be displ on screen
	add si, 1
	add di, 2
	loop writewelc
	mov ax, 01h
	int 16h
	sub ax, ax
	call clearscreen
	;make screen look nice
		mov di, 80				;to center the text
		mov cx, 1000			;for loop
		mov ah, 71h				;clears af for clean background
		mov al, ' '    			;fills screen with spaces to clear it
	call clear
;Draw text editor---------------------------------------------------------
call writemenu
;file stuff===============================================================
getname:
	;get file name----------------------------------------------------------
	mov cx, 0
	mov bx, offset 82h
	mov si, offset fname
	readloop:
		cmp cx, 2000					;in case it gets stuck
		jge end_of_string
			mov ax, [bx]				;move eahc letter of the filename into bx
			cmp ah, 32					;make sure its not a space or illegal char
			jle fake_char
				mov [si], ax			;mov this into the stored
			fake_char:
			cmp ax, 13
			je end_of_string
				add bx, 1
				add si, 1
				add cx, 1
			jmp readloop
			end_of_string:
			mov nsize, cx			;length of file name
; open file-------------------------------
open_file:
	mov ah, 3dh				; set fn to open file
	mov al, 0				;mode
	mov dx, offset fname	;move the file name to the registers
	int 21h					;calls the interrupt to pen the file
	mov word ptr handle, ax
	mov word ptr error_code, ax
	add error_code, "0"
	jnc No_error1
		call error
		;jmp close_program
	No_error1:
;seek end
seek_end:
	mov ah, 42h
	mov al, 02h
	mov bx, handle
	mov cx, 0
	mov dx, 0
	int 21h
	mov word ptr fsize, ax
	mov word ptr error_code, ax
	add error_code, "0"
	jnc No_error3
		call error
		;jmp close_program
	No_error3:
	mov ah, 42h			;rewind pg to beginning
	mov al, 0h
	mov bx, handle
	mov cx, 0
	mov dx, 0
	int 21h
	jnc read_file
		call error
;read file--------------------------------
read_file:
	mov bx, handle
	mov ah, 3fh				;fn read file
	mov cx, fsize				;# bytes to read
	mov dx, offset data		;where it will be stored
	int 21h					;interrupt
	mov word ptr handle, ax
	mov word ptr error_code, ax
	add error_code, "0"
	jnc No_error2
		call error
		;jmp close_program
	No_error2:
;close file-------------------------------
close_file:
	mov ah, 3eh
	mov bx, handle
	int 21h
; Write data to screen===================================================
call write_array
		mov ch, 40h				;hide the cursor
		mov cl, 0
		mov al, 02h
		int 10h
		sub bx, bx
		sub cx, cx
;GET KEY=================================================================
	mov di, 82				;moves cursor to first position in the board
	sub bx, bx				;BX will hold the LOCATION of our cursor
getkey:
		;write cursor to new location
		mov bx, es:[di]			;gets current value in that spots (where cursor is)
		mov bh, 16h				;add cursor styling
		mov al, [si]			;put incrememnted array in to al
		mov es:[di], bx			;puts bx into video memory to be displ on screen

		;actual get key. ip waits here
		mov ax, 01h				;so int 16h can get key
		int 16h					;get key press

		;for save or mode switch to update
		push di
		push ax
		push bx
		call writemenu
		pop bx
		pop ax
		pop di

		;restores color, had to go here so color doesnt get restored instantly
		mov bx, es:[di]			;gets current value in that spots (where cursor was)
		mov bh, 71h				;put styling back for that spot
		mov es:[di], bx			;puts spot back to normal color
	;find out which key was pressed
	cmp ah, 75				; compare with 37 left
		je left					; 37 left arrow
	cmp ah, 72				; 38 is up
		je up						; 38 up arrow
	cmp ah, 77				; find if right arrow
		jne not_right				; 39 right arrow
			call right
			jmp getkey
		not_right:
	cmp ah, 80				; find if down arrow
		je down					; 40 is down arrow
	cmp al, 08				; 08 is backspace
		je backspace
	cmp al, 19				;heck if it is ctrl+s
		je ctrl_save
	cmp al, 27				; find if esc
		jne put_char
			jmp close_program; is esc, then exit
	;if none of the directional keys were pressed then they are trying to input a number
	put_char:
		call insert		; this will allow you to edit filds with a # in them'
		cmp fsize, di
		jge good_size
			add fsize, 1
		good_size:
		jmp getkey

	left:
		;need to write coe to wrap properly
		cmp di, 80					;if you want go left and youre already at the leftmost
		jle min_value
			sub di, 2				;if it was safe then go to the next line
		min_value:
			jmp getkey
	up:
		cmp di, 160
		jl no_up
			sub di, 80
			jmp getkey
			no_up:
			call status_selection
			jmp getkey
	right:
		add di, 2
		cmp di, 2000
		jne not_end_of_scr

		not_end_of_scr:
		jmp getkey
	down:
		add di, 80
		jmp getkey
	backspace:
		sub di, 2
		mov error_code, " "
		mov si, offset error_code
		mov cx, 1					;for loop
		mov ah, 71h
		call print
		jmp left
	ctrl_save:
		call save_file		;save th file by copying to array from screen then to file
		jmp getkey

;CLose program___________________________________________________________
close_program:
	mov ah, 02h				;fn for int10h to move cursor
	sub dx, dx				;moves cursor back to start position
	int 10h
	mov ax, 00h 			;makes sure to just get keypress
	int 16h					;stops scrolling
	call clearscreen
	int 20h					;closes program
code ends
end start
