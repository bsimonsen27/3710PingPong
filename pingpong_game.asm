;==========================================================
; Program Name: pingpong_game.asm
;
;	Authors: Paul Runov & Brendon Simonsen
;
; Description:
; This program will allow 2 players to play pingpong using on the boards provided in our
; ECE3710 class. The game will begin by a player serving the ball by pressing a button. 
; The switches will be used to configure the game. Switches 1&2 will decide the window for
; player 1. Switches 3&4 will decide the windwo for player 2. Switch 5 will be used to 
; select the speed of the ball. The player serving the ball switches each game. To restart
; the game you need to hit the reset button.
;
; Company:
;	Weber State University 
;
; Date			Version		Description
; ----			-------		-----------
; 2/6/2024	V1.0			Initial description
;==========================================================

$include (c8051f020.inc)

	; declaring variables
	dseg at 30h
	old_btn:		ds 1		; old buttons
	pos: 				ds 1		; position of ping pont ball
	speed:			ds 1		; speed of the ball
	p1_window:	ds 1 		; window for player 1, left player
	p2_window:	ds 1		; window for player 2, right player
	buttons:    ds 1    ; button var
	;  is the start position
	bseg 
	serve: dbit 1
	cseg
	mov		wdtcn,#0DEh
	mov		wdtcn,#0ADh

	mov			xbr2,#40H		; activate I/O ports
;------------------------------------------------------
;INITIALIZATION SEQUENCE 
;------------------------------------------------------

	
			mov		A,P1					; Switches moved to accumulator
			anl		A,#3					;	mask the last 
			mov		p1_window,A		; p1_window holds switch values 1&2
			
			mov	  R1, p1_window	; move window variable into r1 for subtraction
			mov		A, #10					; move 4 into accum for subtraction
			subb	A, R1					; 4 - window = the window size
			mov 	p1_window, A	; store the value in p1_window

;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
	
			mov		A,P1
			anl		A,#12				; mask the p2_window switches
			rr		A
			rr 		A
			mov		p2_window,A	; p2_window holds switch values 3&4

			mov	  R1, p2_window	; move window variable into r1 for subtraction
			mov		A, #1					; move 4 into accum for subtraction
			add		A, R1					; 4 - window = the window size
			mov 	p2_window, A	; store the value in p1_window

;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

			mov		A,P1	
			anl		A,#10h						; mask the speed switche
			mov		speed,A						; speed holds switch value 5

			mov		A, #30						; moving 300 into accum 30 ms * 10 ms = 0.3 seconds per LED
			mov 	R1, speed					; move speed into R1 to compare.
			cjne	R1, #1, slower 		; if switch is flipped continue to setup faster speed
			rr		A									; divide 30 / 2 so that speed is 0.15 s
			mov		speed, A					; store value in speed

slower:												; if the switch isn't flipped, the setting is 0.3 s per LED
			mov speed, A
			

;MAIN 
;-------------------------------------------------------
main:
			jb 		serve, call_right_serve		; right serves if bit is 1
			call 	left_serve								; left serves if bit is 0	
			cpl 	serve											; toggle bit for next round after left serve								
move_loop2:
			call move_right									; move right after serve
			call move_left
			sjmp move_loop2  							

call_right_serve:
			call 	right_serve
			cpl 	serve									; toggle bit for next round after left serve				
move_loop1:
			call 	move_left									;move left after serve
			call move_right
			sjmp move_loop1
			

end_game:		
			call end_game

			
			
;-------------------------------------------------------
;RIGHT_SERVE
;-------------------------------------------------------
right_serve:	
			mov		pos, #1					;set the position to the very right
			call	disp_led				;display that position
			
wait_r:											;wait until button has been pressed to move on
			call	chk_btn						
			jnb 	acc.7, wait_r
			ret
										 

;-------------------------------------------------------
;LEFT_SERVE
;-------------------------------------------------------
left_serve:
			mov		pos, #10				;set the position to the very left
			call	disp_led				;display that position

wait_l:											;wait until button has been pressed to move on
			call	chk_btn						
			jnb 	acc.6, wait_l
			ret

;-------------------------------------------------------
;MOVE LEFT
;-------------------------------------------------------
move_left:
		inc pos												; move pos left

		mov		a, pos														
		cjne	a, #11, continue_l			; if position isn't 11 continue to gameplay
		sjmp	end_game								; if position = 11, end game

	

	
continue_l:
		call disp_led									; display the LED


		mov 	A, pos									; move the position into R1
		;mov 	30h, p1_window						; move the player 1 window into R2

		cjne  A, p1_window, LNOTEQUAL   
		call 	speed_delay
		mov 	A, buttons
		anl	  A, #40h
		cjne  A, #40h, move_left
		ret


LNOTEQUAL:
JNC LGREATER											; If position is less than the window, it isn't in the window
		call speed_delay
		sjmp move_left
LGREATER:	
		
		call 	speed_delay
		mov		A, buttons
		anl	  A, #40h
		cjne  A, #40h, move_left
		ret
		

											; If position is greater than window, then it is in the window
	

							
;-------------------------------------------------------
;MOVE RIGHT
;-------------------------------------------------------
move_right:												
		
		dec pos												; move pos right
		
		mov	a, pos
		cjne a, #0, continue_r				; if position 0, end game
		sjmp end_game			
	
	
continue_r:	
		call disp_led									; display the LED

		mov 	A, pos									; move the position into R1
		;mov 	30h, p2_window					; move the player 1 window into R2

		cjne  A, p2_window, RNOTEQUAL 			; compare pos to the window to determine if we are in the window
		;jmp		window_right						; if they are equal, we are in the window
		call 	speed_delay
		mov		A, buttons	
		anl	  A, #80h
		cjne  A, #80h, move_right
		ret

		 

RNOTEQUAL:											; If position is less than the window, it isn't in the window
		JC RGREATER									; jump if we are greater than the window
window_right:										; in window, check buttons
		

		call 	speed_delay
		call  move_right
		ret
													; If position is greater than window, then it is in the windo

RGREATER:

		call speed_delay	
		mov		A, buttons					; speed_delay will check the button								; move buttons into ACC
		anl		A,#80h								; mask to get value of right button only
		cjne	A,#80h,move_right			; check if right button was hit
		ret								; not in window yet, so keep moving right
		
		



;-------------------------------------------------------
;SPEED DELAY
;-------------------------------------------------------
; right button is in P2.7
; left button is in P2.6
speed_delay:
		mov		R6,speed
		mov 	buttons, #0
speed_loop:
		orl 	p2, #0Ch		; clear the LED's
	 	call 	delay  			; call delay 
		call 	chk_btn		; call check buttons
		orl   buttons, A;

		djnz	R6, speed_loop	 


;--------------------------------------------------------
;10 mS DELAY  still need to calculate
;-------------------------------------------------------
delay:	
		mov		R1,#25			; delay 15ms based off 1us machine cycle
loop1:
		mov		R2,#200		; 25*200=5000 djnz instructions
loop2:	
		djnz	R2,loop2	; first loop for 200 times
		djnz	R1,loop1	; second loop for 25 times
		ret							; return to the call


;-------------------------------------------------------
;CHECK_BUTTON
;-------------------------------------------------------
; dont need
chk_btn:	mov A,P2
					cpl A
					xch	A, old_btn
					xrl A, old_btn
					anl A, old_btn
					ret


;-------------------------------------------------------
;DISPLAY_LED
;-------------------------------------------------------

; Display led's
disp_led: mov p3, #0FFh 			;turn LED's off
					orl p2, #003h				;turn LED's off

					mov a, pos 					;	check if 0
					cjne a, #1, not_one	; junp if 0
					clr p3.0						; turn on LED 1
				
					ret									; go back to waiting for a btn

not_one: cjne a,#2,not_two		; compare if pos (which is in accum) is 1
					clr p3.1						; turn on LED 2
					ret									; go back to waiting for a btn

not_two:  cjne a,#3,not_three		; compare if pos is 2
					clr p3.2						; turn on LED 3
					ret									; go back to waiting for a btn

not_three:cjne a,#4,not_four	; compare if pos is 3
					clr p3.3						; turn on LED 4
					ret									; go back to waiting for a btn

not_four:cjne a,#5,not_five	; compare if pos is 4
					clr p3.4						; turn on LED 5
					ret									; go back to waiting for a btn
		
not_five: cjne a,#6,not_six	; compare if pos is 5
					clr p3.5						; turn on LED 6
					ret									; go back to waiting for a btn

not_six: cjne a,#7,not_seven		; compare if pos is 6
					clr p3.6						; turn on LED 7
					ret									; go back to waiting for a btn

not_seven:cjne a,#8,not_eight	; compare if pos is 7
					clr p3.7						; turn on LED 8
					ret									; go back to waiting for a btn

not_eight:cjne a,#9,not_nine	; compare if pos is 8
					clr p2.0						; turn on LED 9
					ret									; go back to waiting for a btn

not_nine:	clr p2.1						; turn on LED 10
					ret									; go back to waiting for a btn

end
