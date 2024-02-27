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
	pos: 				ds 1		; position of ping pong ball
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
; Inputs: Switches on P1 
; Outputs: Window ranges stored in variables p1_window and p2_window
; 				 Speed of the game stored in variable speed
;
; Description: This portion of the code with initiate the values
; for the player windows and speed of the game.
;------------------------------------------------------

	
			mov		A,P1					; Switches moved to accumulator
			anl		A,#3					;	mask the last 2 bits 0000 0011
			mov		p1_window,A		; p1_window holds switch values 1&2
			
			mov	  R1, p1_window	; move window variable into r1 for subtraction
			mov		A, #10					; move 4 into accum for subtraction
			subb	A, R1					; 4 - window = the window size
			mov 	p1_window, A	; store the value in p1_window

;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
	
			mov		A,P1
			anl		A,#12					; mask the p2_window switches
			rr		A
			rr 		A
			mov		p2_window,A		; p2_window holds switch values 3&4

			mov	  R1, p2_window	; move window variable into r1 for subtraction
			mov		A, #1					; move 4 into accum for subtraction
			add		A, R1					; 4 - window = the window size
			mov 	p2_window, A	; store the value in p1_window

;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

			mov		A,P1	
			anl		A,#10h
			;swap  A						; mask the speed switche
			
			mov		speed,A						; speed holds switch value 5
			
			mov		A, #30						; moving 300 into accum 30 ms * 10 ms = 0.3 seconds per LED
			mov 	R1, speed					; move speed into R1 to compare.
			cjne	R1, #0, faster 		; if switch is flipped continue to setup faster speed
															; divide 30 / 2 so that speed is 0.15 s
			mov		speed, A					; store value in speed
			rr		A
faster:	
														; if the switch isn't flipped, the setting is 0.3 s per LED
			mov speed, A
			
			
;-------------------------------------------------------
;MAIN
;
;	Input:
;	Value of the bit stored in 'serve' location of memory
;
;	Output:
;	The initial direction the 'ball' will move
;
; DESCRIPTION:
;	This portion of the code determines the who will be serving
; based on the bit stored in the memory location of serve
;-------------------------------------------------------
main:
			jb 		serve, call_right_serve		; right serves if bit is 1
			cpl 	serve
			call 	left_serve								; left serves if bit is 0	

; This loop is used as the gamplay loop when serving from the left. 
; We will continue to loop through this loop until the end of the game.							
move_loop2:
			
			call move_right				; move right after serve
			call move_left				; when return from move right, we move left
			sjmp move_loop2  			; go back to the start of this loop						

; jump to here if we are serving from the left
call_right_serve:
			cpl 	serve						; toggle bit for next round after left serve
			call 	right_serve

; This is similar to move_loop2 except it is used when we are serving
; from the right
move_loop1:
			call 	move_left				;	move left after serve
			call move_right				; when return from move_left, we move right
			sjmp move_loop1				; jump back to the start of the loop
			

end_game:	
			mov R7, #50 

;-------------------------------------------------------
;RIGHT_SERVE
;
; DESCRIPTION:
;	Continue to loop in this subroutine after game ends. 
; No inputs, only output to P2 and P3 to turn on and off
; the LEDs. 
;
;-------------------------------------------------------
game_over_loop:
			; these flash the LEDs after the game has ended
			mov a, p2
			cpl a
			mov p2, a
					
			mov a, p3
			cpl a
			mov p3, a

			call delay_end
			djnz R7, game_over_loop
			jmp end_game

delay_end:mov r6, #255
delay_1:	mov r5, #255
delay_2:  djnz r5, delay_2
					djnz r6, delay_1
					ret


			
			
;-------------------------------------------------------
;RIGHT_SERVE
;
;	Input:
;	Right button stored on P2.7
;
;	Output:
;	Begins the game
;
; DESCRIPTION:
;	Waits for the right button to be pressed then moves to
; another subroutine to serve the ball
;
;-------------------------------------------------------
right_serve:	
			mov		pos, #1					;set the position to the very right
			call	disp_led				;display that position
			
wait_r:											;wait until button has been pressed to move on
			call	chk_btn						
			jnb 	acc.7, wait_r		;P2 moved to acc, P2.7 holds right button value
														; wait for right button to be pressed
			ret
										 

;-------------------------------------------------------
;LEFT_SERVE
;
;	Input:
;	The left button stored on P2.6
;
;	Output:
;	Begins the game
;
; DESCRIPTION:
; Waits for the left button to be pressed to move to another
; subroutine to serve the ball.
;
;-------------------------------------------------------
left_serve:
			mov		pos, #10				;set the position to the very left
			call	disp_led				;display that position

wait_l:											;wait until button has been pressed to move on
			call	chk_btn						
			jnb 	acc.6, wait_l		;P2 moved to acc. Left button stored in P2.6
														;wait for left button to serve
			ret

;-------------------------------------------------------
;MOVE LEFT
;
; DESCRIPTION:
;	This subroutine will first check if the game is over
; by looking at the location of the ball. Then checks if 
; the ball is in the p1_window. If so, it will check the 
; left button to determine if the ball should be rebounded 
; back or if it should continue moving left. 
;
;-------------------------------------------------------
move_left:
		inc pos												; move pos left

		mov		a, pos														
		cjne	a, #11, continue_l			; if position isn't 11 continue to gameplay
		sjmp	end_game								; if position = 11, end game

	

; continue to move left
continue_l:
		call disp_led									; display the LED


		mov 	A, pos									; move the position into R1
		;mov 	30h, p1_window					 ; move the player 1 window into R2

		cjne  A, p1_window, LNOTEQUAL	; check if we are out of the window
		call 	speed_delay							
		mov 	A, buttons							; next few lines check the btn values
		anl	  A, #40h
		cjne  A, #40h, move_left
		ret


LNOTEQUAL:
JNC LGREATER											; If position is less than the window, it isn't in the window
		call speed_delay
		sjmp move_left
LGREATER:	
		; we are in the window, so we need to check buttons
		call 	speed_delay
		mov		A, buttons
		anl	  A, #40h
		cjne  A, #40h, move_left
		ret
							
;-------------------------------------------------------
;MOVE RIGHT.
;
; DESCRIPTION:
;	This subroutine will first check if the game is over
; by looking at the location of the ball. Then checks if 
; the ball is in the p2_window. If so, it will check 
; the right button to determine if the ball should be 
; rebounded back or if it should continue
; moving right. 
;
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

		cjne  A, p2_window, RNOTEQUAL ; compare pos to the window to determine if we are in the window
		;jmp		window_right					; if they are equal, we are in the window
		call 	speed_delay
		; check buttons
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
		mov		A, buttons					; speed_delay will check the button	
		anl		A,#80h							; mask to get value of right button only
		cjne	A,#80h,move_right		; check if right button was hit
		ret												; not in window yet, so keep moving right
		
		



;-------------------------------------------------------
;SPEED DELAY
;
; DESCRIPTION:
; This function takes in the value stored on the 'speed'
; variable which come from switch 5. This determines the
; speed at which the ball will travel. It also checks the 
; buttons every 10 ms.
;
;-------------------------------------------------------
; right button is in P2.7
; left button is in P2.6
speed_delay:
		mov		R6,speed
		mov 	buttons, #0
speed_loop:
		orl 	p2, #0Ch		; clear the LED's
	 	call 	delay  			; call delay 
		call 	chk_btn			; call check buttons
		orl   buttons, A

		djnz	R6, speed_loop	 


;--------------------------------------------------------
;10 mS DELAY
;
; DESCRIPTION:
; This will delay for about 10ms. It doesn't take any inputs
; or publish any outputs. R1 and R2 are 
;
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
;
; DESCRIPTION:
; Checks if the buttons have been pressed. Has code to 
; protect against the button being held down. 
;
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
;
;	Input:
;	The value stored in the variable 'pos'
;
;	Output:
;	The LED that will turn to represent the ball's location
;
; DESCRIPTION:
;	This subroutine will turn off all the LEDs then compares 
; the value stored in 'pos' variable to determine what LED
; should be turned on.
;
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