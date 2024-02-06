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
	p1_window		ds 1 		; window for player 1
	p2_window		ds 1		; window for player 2

	cseg
	mov		wdtcn,#0DEh
	mov		wdtcn,#0ADh

	mov			xbr2,#40H		; activate I/O ports
;--------------------------------------------
	
	mov		A,P1				; Switches moved to accumulator
	anl		A,#3				;	mask the last 
	mov		p1_window,A	; p1_window holds switch values 1&2
	mov		A,P1
	anl		A,#12				; mask the p2_window switches
	mov		p2_window,A	; p2_window holds switch values 3&4
	mov		A,P1
	anl		A,#10h			; mask the speed switche
	mov		speed,A			; p2_window holds switch value 5
