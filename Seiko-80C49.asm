;
;	Disassembled by:
;		DASMx object code disassembler
;		(c) Copyright 1996-2003   Conquest Consultants
;		Version 1.40 (Oct 18 2003)
;
;	File:		../SEIKO.BIN
;
;	Size:		2048 bytes
;	Checksum:	7097
;	CRC-32:		483FEF77
;
;	Date:		Sun Mar 12 14:09:02 2017
;
;	CPU:		Intel 8048 (MCS-48 family)
;
;
;

	org 00000H

;
reset:
	nop
	jmp initialize
;
interrupt:
	orl p2,#040H	; set P2.6 (/READY) output high
	jmp L006E	; jump to interrupt service routine

;
counterinterrupt:
	xch a,r5
	mov a,r4
	outl bus,a
	stop tcnt
	dis tcnti
	mov a,r5
	cpl f1
	retr		; return and restore PSW

;
initialize:
	; these appear unnecessary as P1/P2 are high-impedance upon RESET
	orl p1,#0FFH	; set P1 high-impedance for use as input
	orl p2,#0FFH	; set P2 high-impedance for use as input

	; output zero to BUS
	clr a
	outl bus,a
	
	; clear internal RAM location @020H
	mov r0,#020H
	mov @r0,a

; 
L0018:
	; Clears internal RAM locations @021H through @058H
	clr a		; used to write zeroes
	mov r0,#021H	; start address
	mov r1,#038H	; number of bytes to clear
L001D:
	mov @r0,a	; clear @R0
	inc r0		; increment R0
	djnz r1,L001D	; loop for R1 times
	
	call clear_line_buffer	; clear line buffer
L0023:
	call L00F0
	call clear_line_buffer	; clear line buffer
L0027:
	mov r0,#022H
	mov a,@r0
	mov r3,a
	mov r7,#058H
	mov r0,#020H
	in a,p2
	jb4 L003D
	mov a,@r0
	jb0 L0039
	mov @r0,#001H
	jmp L0069

;
L0039:
	in a,p2
	cpl a
	jb4 L0039
L003D:
	mov @r0,#000H
	in a,p2
	cpl a
	jb3 L0069
L0043:
	clr f1		; clear F1 flag (ready for input data)
	en i		; enable external interrupts
	anl p2,#0BFH	; clear P2.6 (!READY) output
	orl p2,#03FH	; set bits used as inputs to high impedance state
	mov a,r7
	mov r1,a
L004B:
	jf1 L0074	; jump if F1 (data received)
	in a,p2
	jb4 L005B
	mov a,@r0
	jb0 L0057
	mov @r0,#001H
	jmp L0069

;
L0057:
	in a,p2
	cpl a
	jb4 L0057
L005B:
	mov @r0,#000H
	jf1 L0074
	in a,p2
	jb3 L004B
	mov a,r7
	add a,#0A8H
	jf1 L0074
	jnz L004B

L0069:
	orl p2,#040H	; set P2.6
	dis i		; disable external interrupts
	jmp L0018	; jump

; Interrupt service routine (triggered by INT input)
; External data is read from P1, stored in R4, and F1 flag is set.
L006E:
	mov r4,a	; save A
	in a,p1		; get external input data from P1
	xch a,r4	; restore A; move input data to R4
	dis i		; disable external interrupts
	cpl f1		; set (complement) F1 flag (indicates data received)
	retr		; return from interrupt and restore PSW

;
L0074:
	mov a,r4	; load received byte
	jb7 L0089	; jump if bit 7 set
	add a,#0E0H
	jc L008F
	xrl a,#0EDH
	jnz L0081
	jmp L0023

;
L0081:
	xrl a,#015H
	jnz L0043
	call clear_line_buffer	; clear line buffer
	jmp L0027

;
L0089:
	add a,#060H
	jb6 L0043
	add a,#060H
L008F:
	add a,#060H
	mov @r1,a
	inc r7
	djnz r3,L0043
	jmp L0023
	
; COMMENTED OUT: ORG DIRECTIVE USED BELOW IN-LIEU OF PADDING
; Padding (89-bytes) to align next page of ROM
;	db 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H
;	db 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H
;	db 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H
;	db 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H
;	db 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H
;	db 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H

	org 000F0H	; align code so line width lookup table (below) lies from 00109H through 00110H

;
L00F0:
	in a,p2		; load P2
	mov r3,a	; store in R3
	in a,p2		; load P2 again
	xrl a,r3	; test if any P2 bits changed
	anl a,#027H	; mask out all but print head home switch and line width
	jnz L00F0	; loop back if any bits changed to load P2 again
	mov a,r3	; load original P2 value
	jb5 L00FD	; jump if print head home switch
	call L01C1

; Get line width from lookup table
L00FD:
	mov a,r3	; load R3
	anl a,#007H	; mask out upper 5-bits to yield 3-bit line width selector value
	add a,#009H	; add offset to lookup table ROM address LSB
	movp a,@a	; get line width from lookup table
	mov r3,a	; store line width in R3
	mov r0,#022H	; load pointer to @022H
	mov @r0,a	; store line width in RAM at pointer
	jmp L0111	; jump over lookup table

; Line width lookup table (8-bytes).
;   0=40 characters; 1=32 characters; 2=25 characters; 3=24 characters
;   4=20 characters; 5=17 characters; 6=16 characters; 7=13 characters
	db 028H, 020H, 019H, 018H, 014H, 011H, 010H, 00DH

;
L0111:
	mov r7,#058H	; 88
	mov r4,#0D9H	; 217
	mov r5,#029H	; 41
	mov r0,#080H	; 128
L0119:
	clr f0
	orl p2,#03FH	; set P2 bits used as inputs to high impedance
L011C:
	anl p2,#07FH
	mov a,r0
	outl bus,a
	in a,p2
	nop
	jb5 L0126
	jmp L0136

;
L0126:
	clr f0
	djnz r4,L012D
	djnz r5,L012F
	jmp L0238

;
L012D:
	nop
	nop
L012F:
	nop
	nop
	nop
	in a,p2
	nop
	jb5 L0119
L0136:
	cpl f0
	jf0 L011C
	mov r5,#001H
	clr f0
L013C:
	mov r0,#023H
	mov @r0,#03DH
	inc r0
	mov @r0,#0AEH
	call L0200
	mov a,r7
	mov r1,a
	mov a,@r1
	mov r4,a
	mov r0,#051H	; point to 5-byte buffer for character dot matrix data
	jmp LOOKUP1	; jump to load 5-byte buffer from lookup tables

; After lookup tables, execution jumps here.
LOOKUPX:
	mov r0,#023H
	mov @r0,#03DH
	inc r0
	mov @r0,#0AEH
	call L0200
	jf0 LOOKUPX
	djnz r5,LOOKUPX
	mov r6,#051H
L015C:
	mov a,r6
	mov r1,a
	mov a,@r1
	orl a,#080H
	mov r4,a
	clr f1
	mov a,#0ECH
	mov t,a
	mov r0,#023H
	mov @r0,#03DH
	inc r0
	mov @r0,#0AEH
L016D:
	jnt0 L01A2
	jf0 L0191
L0171:
	cpl f0
	mov a,r4
	outl bus,a
	strt cnt
	en tcnti
	mov r4,#080H
	mov r0,#023H
	mov @r0,#022H
L017C:
	mov r0,#023H
	mov a,@r0
	add a,#0FFH
	mov @r0,a
	jnc L018B
	in a,p2
	nop
	nop
	jf1 L018B
	jmp L017C

;
L018B:
	dis tcnti
	stop tcnt
	mov a,r4
	outl bus,a
	jmp L015C

;
L0191:
	jnt0 L01B5
	mov r0,#024H
	mov a,@r0
	add a,#0FFH
	mov @r0,a
	dec r0
	mov a,@r0
	addc a,#0FFH
	mov @r0,a
	jc L016D
L01A0:
	jmp L0238

;
L01A2:
	jf0 L01B5
	jt0 L0171
	mov r0,#024H
	mov a,@r0
	add a,#0FFH
	mov @r0,a
	dec r0
	mov a,@r0
	addc a,#0FFH
	mov @r0,a
	jc L016D
	jmp L0238

;
L01B5:
	clr f0
	inc r6
	mov a,r6
	add a,#0AAH
	jnz L015C
	mov r5,#002H
	inc r7
	djnz r3,L013C
L01C1:
	mov r0,#023H	; load pointer
	mov @r0,#02BH	; 43
	inc r0		; increment pointer
	mov @r0,#067H	; 103
L01C8:
	clr f0		; clear F0 flag
	orl p2,#03FH	; set P2 input pins to high impedance state
L01CB:
	anl p2,#07FH	; 
	mov a,#080H	; carriage motor bit
	outl bus,a	; turn on carriage motor
	mov r0,#024H	; load pointer
	mov a,@r0	; get value
	add a,#0FFH	; add 0FFH to value
	mov @r0,a	; store value
	dec r0		; decrement pointer
	mov a,@r0	; load value
	addc a,#0FFH	; add with carry 0FFH to value
	mov @r0,a	; store value
	jnc L01A0	; jump if no carry
	in a,p2		; load P2
	cpl a		; complement
	jb5 L01C8	; jump if bit 5 (print head home switch)
	cpl f0		; complement F0
	jf0 L01CB	; loop while F0

	clr a		; clear A
	outl bus,a	; set BUS to zero
	orl p2,#080H	; set P2.7 high
	mov r0,#006H	; number of times to delay
L01EA:
	clr a		; clear A
	mov r1,a	; clear R1
L01EC:
	djnz r1,L01EC	; inner delay loop (256 iterations)
	djnz r0,L01EA	; outer delay loop (R0 iterations)
	ret		; return

; COMMENTED OUT: ORG DIRECTIVE USED BELOW IN-LIEU OF PADDING
; Padding (15-bytes) to align next page of ROM
;	db 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H
;	db 000H, 000H, 000H, 000H, 000H, 000H, 000H

	org 00200H

;
L0200:
	jnt0 L0217	; jump if not T0 (low)
	jf0 L0206	; jump if F0 set
L0204:
	cpl f0		; complement F0
	ret		; return

;
L0206:
	jnt0 L022A
	mov r0,#024H
	mov a,@r0
	add a,#0FFH
	mov @r0,a
	dec r0
	mov a,@r0
	addc a,#0FFH
	mov @r0,a
	jc L0200
	jmp L0238

;
L0217:
	jf0 L022A	; jump if F0 flag set
	jt0 L0204	; jump if T0 is high
	mov r0,#024H	; load pointer
	mov a,@r0	; load value at pointer
	add a,#0FFH	; add 0FFH to value
	mov @r0,a	; store value
	dec r0		; decrement pointer
	mov a,@r0	; load value
	addc a,#0FFH	; add with carry 0FFH to value
	mov @r0,a	; store value
	jc L0200	; jump if carry
	jmp L0238	; jump

;
L022A:
	clr f0		; clear F0 flag
	ret		; return
	
; Clears 40-byte line buffer (@058H through @07FH) by writing #060H (space character) to
; each character location.
clear_line_buffer:
	clr c		; clear carry bit
	mov r0,#058H	; starting location
	mov r1,#028H	; number of times to loop
	mov a,#060H	; value to write
L0233:
	mov @r0,a	; write A to @R0
	inc r0		; increment pointer
	djnz r1,L0233	; loop R1 times
	ret		; return

;
L0238:
	clr a		; zero
	outl bus,a	; set BUS to zero
	mov psw,a	; set PSW to zero (resets stack pointer)
	dis i		; disable external interrupt
	dis tcnti	; disable timer/counter interrupt
	stop tcnt	; stop timer/counter
	call L024C	; do-nothing subroutine (returns)
	orl p1,#0FFH	; set P1 to high impedance
	orl p2,#0FFH	; set P2 to high impedance

; Endless loop while P2.4 is high
L0244:
	in a,p2		; load P2
	jb4 L0244	; loop while P2.4 is high
	in a,p2		; load P2 again
	jb4 L0244	; loop while P2.4 is high
	jmp initialize	; jump to initialize

; Do-nothing subroutine.
L024C:
	retr		; return
	
; COMMENTED OUT: ORG DIRECTIVE USED BELOW IN-LIEU OF PADDING
; Padding (269-bytes) to align character dot matrix tables at end of ROM
;	db 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H
;	db 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H
;	db 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H
;	db 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H
;	db 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H
;	db 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H
;	db 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H
;	db 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H
;	db 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H
;	db 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H
;	db 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H
;	db 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H
;	db 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H
;	db 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H
;	db 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H
;	db 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H
;	db 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H

	org 0035AH	; align code so lookup table lies from 00360H through 003FFH

; Get character dot matrix data for column 1
LOOKUP1:
	mov a,r4	; load data byte
	movp a,@a	; load A from ROM current page
	mov @r0,a	; store A to @R0
	inc r0		; increment pointer
	jmp LOOKUP2	; jump to next lookup table

; Character Dot Matrix Data - Column 1 (160 characters: ASCII 020H–07FH and 0A0H–0DFH)
	db 000H, 000H, 000H, 014H, 024H, 023H, 036H, 000H, 000H, 000H, 012H, 008H, 000H, 008H, 000H, 020H
	db 03EH, 000H, 042H, 021H, 018H, 027H, 03CH, 001H, 036H, 006H, 000H, 000H, 008H, 014H, 000H, 002H
	db 032H, 07CH, 07FH, 03EH, 07FH, 07FH, 07FH, 03EH, 07FH, 000H, 020H, 07FH, 07FH, 07FH, 07FH, 03EH
	db 07FH, 03EH, 07FH, 026H, 001H, 03FH, 01FH, 03FH, 063H, 007H, 061H, 000H, 015H, 000H, 004H, 040H
	db 000H, 024H, 000H, 000H, 038H, 038H, 000H, 008H, 000H, 000H, 020H, 000H, 000H, 07CH, 000H, 038H
	db 07CH, 008H, 000H, 048H, 000H, 000H, 01CH, 03CH, 044H, 00CH, 044H, 000H, 000H, 041H, 002H, 000H
	db 000H, 070H, 000H, 040H, 010H, 000H, 00AH, 004H, 020H, 018H, 048H, 048H, 008H, 040H, 054H, 018H
	db 008H, 001H, 010H, 00EH, 042H, 022H, 042H, 00AH, 008H, 008H, 042H, 002H, 04AH, 042H, 002H, 006H
	db 008H, 00AH, 00EH, 004H, 000H, 044H, 040H, 042H, 022H, 000H, 078H, 03FH, 002H, 004H, 032H, 002H
	db 02AH, 038H, 040H, 00AH, 004H, 040H, 04AH, 004H, 00EH, 07CH, 07EH, 07EH, 00EH, 042H, 002H, 007H

; COMMENTED OUT: ORG DIRECTIVE USED BELOW IN-LIEU OF PADDING
; Padding (90-bytes) to align next page of ROM
;	db 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H
;	db 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H
;	db 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H
;	db 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H
;	db 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H
;	db 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H

	org 0045AH	; align code so lookup table lies from 00460H through 004FFH

; Get character dot matrix data for column 2
LOOKUP2:
	mov a,r4	; load data byte
	movp a,@a	; load A from ROM current page
	mov @r0,a	; store A to @R0
	inc r0		; increment pointer
	jmp LOOKUP3	; jump to next lookup table

; Character Dot Matrix Data - Column 2 (160 characters: ASCII 020H–07FH and 0A0H–0DFH)
	db 000H, 000H, 007H, 07FH, 02AH, 013H, 049H, 005H, 01CH, 041H, 00CH, 008H, 050H, 008H, 060H, 010H
	db 051H, 042H, 061H, 041H, 014H, 045H, 04AH, 071H, 049H, 049H, 036H, 056H, 014H, 014H, 041H, 001H
	db 049H, 012H, 049H, 041H, 041H, 049H, 009H, 041H, 008H, 041H, 040H, 008H, 040H, 002H, 004H, 041H
	db 009H, 041H, 009H, 049H, 001H, 040H, 020H, 040H, 014H, 008H, 051H, 07FH, 016H, 041H, 002H, 040H
	db 000H, 054H, 07FH, 038H, 044H, 054H, 004H, 054H, 07FH, 044H, 040H, 07FH, 041H, 004H, 07CH, 044H
	db 014H, 014H, 07CH, 054H, 004H, 03CH, 020H, 040H, 028H, 050H, 064H, 008H, 000H, 041H, 001H, 000H
	db 000H, 050H, 000H, 040H, 020H, 018H, 04AH, 044H, 010H, 008H, 048H, 028H, 07CH, 048H, 054H, 000H
	db 008H, 041H, 008H, 002H, 042H, 012H, 03FH, 00AH, 046H, 007H, 042H, 00FH, 04AH, 022H, 03FH, 048H
	db 046H, 04AH, 000H, 045H, 07FH, 024H, 042H, 02AH, 012H, 040H, 000H, 044H, 042H, 002H, 002H, 012H
	db 02AH, 024H, 028H, 03EH, 07FH, 042H, 04AH, 005H, 040H, 000H, 040H, 042H, 002H, 042H, 004H, 005H

; COMMENTED OUT: ORG DIRECTIVE USED BELOW IN-LIEU OF PADDING
; Padding (90-bytes) to align next page of ROM
;	db 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H
;	db 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H
;	db 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H
;	db 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H
;	db 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H
;	db 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H

	org 0055AH	; align code so lookup table lies from 00560H through 005FFH

; Get character dot matrix data for column 3
LOOKUP3:
	mov a,r4	; load data byte
	movp a,@a	; load A from ROM current page
	mov @r0,a	; store A to @R0
	inc r0		; increment pointer
	jmp LOOKUP4	; jump to next lookup table
	
; Character Dot Matrix Data - Column 3 (160 characters: ASCII 020H–07FH and 0A0H–0DFH)
	db 000H, 04FH, 000H, 014H, 07FH, 008H, 055H, 003H, 022H, 022H, 03FH, 03EH, 030H, 008H, 060H, 008H
	db 049H, 07FH, 051H, 045H, 012H, 045H, 049H, 009H, 049H, 049H, 036H, 036H, 022H, 014H, 022H, 051H
	db 079H, 011H, 049H, 041H, 041H, 049H, 009H, 049H, 008H, 07FH, 041H, 014H, 040H, 00CH, 008H, 041H
	db 009H, 051H, 019H, 049H, 07FH, 040H, 040H, 038H, 008H, 070H, 049H, 041H, 07CH, 041H, 001H, 040H
	db 003H, 054H, 044H, 044H, 044H, 054H, 07EH, 054H, 004H, 07DH, 040H, 010H, 07FH, 078H, 004H, 044H
	db 014H, 014H, 008H, 054H, 03FH, 040H, 040H, 030H, 010H, 050H, 054H, 036H, 077H, 036H, 002H, 000H
	db 000H, 070H, 00FH, 070H, 040H, 018H, 02AH, 034H, 078H, 04CH, 078H, 018H, 008H, 048H, 054H, 058H
	db 008H, 03DH, 07CH, 043H, 07EH, 00AH, 002H, 07FH, 042H, 042H, 042H, 042H, 040H, 012H, 042H, 040H
	db 04AH, 03EH, 04EH, 03DH, 008H, 01FH, 042H, 012H, 07FH, 020H, 002H, 044H, 042H, 004H, 07FH, 022H
	db 02AH, 022H, 010H, 04AH, 004H, 042H, 04AH, 045H, 020H, 07EH, 020H, 042H, 042H, 040H, 001H, 007H

; COMMENTED OUT: ORG DIRECTIVE USED BELOW IN-LIEU OF PADDING
; Padding (90-bytes) to align next page of ROM
;	db 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H
;	db 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H
;	db 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H
;	db 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H
;	db 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H
;	db 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H

	org 0065AH	; align code so lookup table lies from 00660H through 006FFH

; Get character dot matrix data for column 4
LOOKUP4:
	mov a,r4	; load data byte
	movp a,@a	; load A from ROM current page
	mov @r0,a	; store A to @R0
	inc r0		; increment pointer
	jmp LOOKUP5	; jump to next lookup table
	
; Character Dot Matrix Data - Column 4 (160 characters: ASCII 020H–07FH and 0A0H–0DFH)
	db 000H, 000H, 007H, 07FH, 02AH, 064H, 022H, 000H, 041H, 01CH, 00CH, 008H, 000H, 008H, 000H, 004H
	db 045H, 040H, 049H, 04BH, 07FH, 045H, 049H, 005H, 049H, 029H, 000H, 000H, 041H, 014H, 014H, 009H
	db 041H, 012H, 049H, 041H, 022H, 049H, 009H, 049H, 008H, 041H, 03FH, 022H, 040H, 002H, 010H, 041H
	db 009H, 021H, 029H, 049H, 001H, 040H, 020H, 040H, 014H, 008H, 045H, 041H, 016H, 07FH, 002H, 040H
	db 005H, 078H, 044H, 044H, 07FH, 054H, 005H, 054H, 004H, 040H, 03DH, 028H, 040H, 004H, 004H, 044H
	db 014H, 014H, 004H, 054H, 044H, 040H, 020H, 040H, 028H, 03CH, 04CH, 041H, 000H, 008H, 004H, 000H
	db 000H, 000H, 001H, 000H, 000H, 000H, 01AH, 014H, 004H, 048H, 048H, 07CH, 028H, 078H, 07CH, 040H
	db 008H, 009H, 002H, 022H, 042H, 07FH, 042H, 00AH, 022H, 03EH, 042H, 03FH, 020H, 02AH, 04AH, 020H
	db 032H, 009H, 020H, 005H, 010H, 004H, 042H, 02AH, 00EH, 01FH, 004H, 044H, 022H, 008H, 002H, 052H
	db 02AH, 020H, 028H, 04AH, 014H, 07EH, 04AH, 025H, 01EH, 040H, 018H, 042H, 022H, 020H, 002H, 000H

; COMMENTED OUT: ORG DIRECTIVE USED BELOW IN-LIEU OF PADDING
; Padding (90-bytes) to align next page of ROM
;	db 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H
;	db 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H
;	db 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H
;	db 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H
;	db 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H
;	db 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H

	org 0075AH	; align code so lookup table ends at 007FFH

; Get character dot matrix data for column 5
LOOKUP5:
	mov a,r4	; load data byte
	movp a,@a	; load A from ROM current page
	mov @r0,a	; store A to @R0
	jmp LOOKUPX	; Done with lookup tables. Jump back.

; COMMENTED OUT: ORG DIRECTIVE USED BELOW IN-LIEU OF PADDING
; Padding (1-byte) to align lookup table (because the INC R0 instruction is not used for 5th lookup)
;	db 000H

	org 00760H	; align lookup table to 00760H through 007FFH

; Character Dot Matrix Data - Column 5 (160 characters: ASCII 020H–07FH and 0A0H–0DFH)
	db 000H, 000H, 000H, 014H, 012H, 062H, 050H, 000H, 000H, 000H, 012H, 008H, 000H, 008H, 000H, 002H
	db 03EH, 000H, 046H, 031H, 010H, 039H, 030H, 003H, 036H, 01EH, 000H, 000H, 000H, 014H, 008H, 006H
	db 03EH, 07CH, 036H, 022H, 01CH, 041H, 001H, 07AH, 07FH, 000H, 001H, 041H, 040H, 07FH, 07FH, 03EH
	db 006H, 05EH, 046H, 032H, 001H, 03FH, 01FH, 03FH, 063H, 007H, 043H, 000H, 015H, 000H, 004H, 040H
	db 000H, 040H, 038H, 044H, 000H, 058H, 005H, 03CH, 078H, 000H, 000H, 044H, 000H, 078H, 078H, 038H
	db 008H, 07CH, 004H, 024H, 040H, 07CH, 01CH, 03CH, 044H, 000H, 044H, 041H, 000H, 000H, 002H, 000H
	db 000H, 000H, 001H, 000H, 000H, 000H, 00EH, 00CH, 000H, 038H, 048H, 008H, 018H, 040H, 000H, 038H
	db 008H, 007H, 001H, 01EH, 042H, 002H, 03EH, 00AH, 01EH, 002H, 07EH, 002H, 01CH, 046H, 046H, 01EH
	db 01EH, 008H, 01EH, 004H, 000H, 004H, 040H, 006H, 012H, 000H, 078H, 044H, 01EH, 030H, 032H, 00EH
	db 040H, 070H, 046H, 04AH, 00CH, 040H, 07EH, 01CH, 000H, 038H, 000H, 07EH, 01EH, 018H, 000H, 000H
