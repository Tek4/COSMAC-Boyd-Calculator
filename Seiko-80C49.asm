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
	org	00000H
;
reset:
	nop
	jmp	initialize
;
interrupt:
	orl	p2,#040H	; set P2.3 (input !FEED / PF key)
	jmp	L006E		; jump to interrupt service routine

;
counterinterrupt:
	xch	a,r5
	mov	a,r4
	outl	bus,a
	stop	tcnt
	dis	tcnti
	mov	a,r5
	cpl	f1
	retr
;
initialize:
	; these appear unnecessary as P1/P2 are high-impedance upon RESET
	orl	p1,#0FFH	; set P1 high-impedance for use as input
	orl	p2,#0FFH	; set P2 high-impedance for use as input

	; output zero to BUS
	clr	a
	outl	bus,a
	
	; clear Data RAM location @020H
	mov	r0,#020H
	mov	@r0,a

; 
L0018:
	; Clears Data RAM locations @021H through @058H
	clr	a		; used to write zeroes
	mov	r0,#021H	; start address
	mov	r1,#038H	; number of bytes to clear
L001D:
	mov	@r0,a		; clear @R0
	inc	r0		; increment R0
	djnz	r1,L001D	; loop for R1 times
	
	call	L022C		; initialize 40-byte buffer (@058-@07F) to #060H
L0023:
	call	L00F0
	call	L022C		; initialize 40-byte buffer (@058-@07F) to #060H
L0027:
	mov	r0,#022H
	mov	a,@r0
	mov	r3,a
	mov	r7,#058H
	mov	r0,#020H
	in	a,p2
	jb4	L003D
	mov	a,@r0
	jb0	L0039
	mov	@r0,#001H
	jmp	L0069
;
L0039:
	in	a,p2
	cpl	a
	jb4	L0039
L003D:
	mov	@r0,#000H
	in	a,p2
	cpl	a
	jb3	L0069
L0043:
	clr	f1		; clear F1 flag (ready for input data)
	en	i		; enable external interrupts
	anl	p2,#0BFH	; clear P2.6 (!READY) output
	orl	p2,#03FH	; set P2.0 through P2.5
	mov	a,r7
	mov	r1,a
L004B:
	jf1	L0074		; jump if F1 (data received)
	in	a,p2
	jb4	L005B
	mov	a,@r0
	jb0	L0057
	mov	@r0,#001H
	jmp	L0069
;
L0057:
	in	a,p2
	cpl	a
	jb4	L0057
L005B:
	mov	@r0,#000H
	jf1	L0074
	in	a,p2
	jb3	L004B
	mov	a,r7
	add	a,#0A8H
	jf1	L0074
	jnz	L004B
L0069:
	orl	p2,#040H
	dis	i
	jmp	L0018

; Interrupt service routine (triggered by INT input)
; 
L006E:
	mov	r4,a	; save A
	in	a,p1	; get external input data from P1
	xch	a,r4	; restore A; move input data to R4
	dis	i	; disable external interrupts
	cpl	f1	; complement flag F1 (indicate data received?)
	retr		; return from interrupt
	
;
L0074:
	mov	a,r4		; load received byte
	jb7	L0089		; jump if bit 7 set
	add	a,#0E0H
	jc	L008F
	xrl	a,#0EDH
	jnz	L0081
	jmp	L0023
;
L0081:
	xrl	a,#015H
	jnz	L0043
	call	L022C
	jmp	L0027
;
L0089:
	add	a,#060H
	jb6	L0043
	add	a,#060H
L008F:
	add	a,#060H
	mov	@r1,a
	inc	r7
	djnz	r3,L0043
	jmp	L0023
	
; Padding (89-bytes) to align next page of ROM
	db	000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H
	db	000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H
	db	000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H
	db	000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H
	db	000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H
	db	000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H

;
L00F0:
	in	a,p2
	mov	r3,a
	in	a,p2
	xrl	a,r3
	anl	a,#027H
	jnz	L00F0
	mov	a,r3
	jb5	L00FD
	call	L01C1
L00FD:
	mov	a,r3
	anl	a,#007H
	add	a,#009H
	movp	a,@a
	mov	r3,a
	mov	r0,#022H
	mov	@r0,a
	jmp	L0111

; Data table (8-bytes)
	db	028H, 020H, 019H, 018H, 014H, 011H, 010H, 00DH

;
L0111:
	mov	r7,#058H
	mov	r4,#0D9H
	mov	r5,#029H
	mov	r0,#080H
L0119:
	clr	f0
	orl	p2,#03FH
L011C:
	anl	p2,#07FH
	mov	a,r0
	outl	bus,a
	in	a,p2
	nop
	jb5	L0126
	jmp	L0136

;
L0126:
	clr	f0
	djnz	r4,L012D
	djnz	r5,L012F
	jmp	L0238

;
L012D:
	nop
	nop
L012F:
	nop
	nop
	nop
	in	a,p2
	nop
	jb5	L0119
L0136:
	cpl	f0
	jf0	L011C
	mov	r5,#001H
	clr	f0
L013C:
	mov	r0,#023H
	mov	@r0,#03DH
	inc	r0
	mov	@r0,#0AEH
	call	L0200
	mov	a,r7
	mov	r1,a
	mov	a,@r1
	mov	r4,a
	mov	r0,#051H	; point to 5-byte buffer for character dot matrix data
	jmp	L035A		; jump to get character dot matrix data

;
L014D:
	mov	r0,#023H
	mov	@r0,#03DH
	inc	r0
	mov	@r0,#0AEH
	call	L0200
	jf0	L014D
	djnz	r5,L014D
	mov	r6,#051H
L015C:
	mov	a,r6
	mov	r1,a
	mov	a,@r1
	orl	a,#080H
	mov	r4,a
	clr	f1
	mov	a,#0ECH
	mov	t,a
	mov	r0,#023H
	mov	@r0,#03DH
	inc	r0
	mov	@r0,#0AEH
L016D:
	jnt0	L01A2
	jf0	L0191
L0171:
	cpl	f0
	mov	a,r4
	outl	bus,a
	strt	cnt
	en	tcnti
	mov	r4,#080H
	mov	r0,#023H
	mov	@r0,#022H
L017C:
	mov	r0,#023H
	mov	a,@r0
	add	a,#0FFH
	mov	@r0,a
	jnc	L018B
	in	a,p2
	nop
	nop
	jf1	L018B
	jmp	L017C

;
L018B:
	dis	tcnti
	stop	tcnt
	mov	a,r4
	outl	bus,a
	jmp	L015C

;
L0191:
	jnt0	L01B5
	mov	r0,#024H
	mov	a,@r0
	add	a,#0FFH
	mov	@r0,a
	dec	r0
	mov	a,@r0
	addc	a,#0FFH
	mov	@r0,a
	jc	L016D
L01A0:
	jmp	L0238

;
L01A2:
	jf0	L01B5
	jt0	L0171
	mov	r0,#024H
	mov	a,@r0
	add	a,#0FFH
	mov	@r0,a
	dec	r0
	mov	a,@r0
	addc	a,#0FFH
	mov	@r0,a
	jc	L016D
	jmp	L0238

;
L01B5:
	clr	f0
	inc	r6
	mov	a,r6
	add	a,#0AAH
	jnz	L015C
	mov	r5,#002H
	inc	r7
	djnz	r3,L013C
L01C1:
	mov	r0,#023H
	mov	@r0,#02BH
	inc	r0
	mov	@r0,#067H
L01C8:
	clr	f0
	orl	p2,#03FH
L01CB:
	anl	p2,#07FH
	mov	a,#080H
	outl	bus,a
	mov	r0,#024H
	mov	a,@r0
	add	a,#0FFH
	mov	@r0,a
	dec	r0
	mov	a,@r0
	addc	a,#0FFH
	mov	@r0,a
	jnc	L01A0
	in	a,p2
	cpl	a
	jb5	L01C8
	cpl	f0
	jf0	L01CB
	clr	a
	outl	bus,a
	orl	p2,#080H
	mov	r0,#006H
L01EA:
	clr	a
	mov	r1,a
L01EC:
	djnz	r1,L01EC
	djnz	r0,L01EA
	ret

; (15-bytes)
	db	000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H
	db	000H, 000H, 000H, 000H, 000H, 000H, 000H

;
L0200:
	jnt0	L0217
	jf0	L0206
L0204:
	cpl	f0
	ret

;
L0206:
	jnt0	L022A
	mov	r0,#024H
	mov	a,@r0
	add	a,#0FFH
	mov	@r0,a
	dec	r0
	mov	a,@r0
	addc	a,#0FFH
	mov	@r0,a
	jc	L0200
	jmp	L0238

;
L0217:
	jf0	L022A
	jt0	L0204
	mov	r0,#024H
	mov	a,@r0
	add	a,#0FFH
	mov	@r0,a
	dec	r0
	mov	a,@r0
	addc	a,#0FFH
	mov	@r0,a
	jc	L0200
	jmp	L0238

;
L022A:
	clr	f0
	ret
	
; Write #060H to Data RAM locations @058H through @07FH (40 bytes)
L022C:
	clr	c		; clear carry bit
	mov	r0,#058H	; starting location
	mov	r1,#028H	; number of times to loop
	mov	a,#060H		; value to write
L0233:
	mov	@r0,a		; write A to @R0
	inc	r0		; increment pointer
	djnz	r1,L0233	; loop R1 times
	ret			; return

;
L0238:
	clr	a
	outl	bus,a
	mov	psw,a
	dis	i
	dis	tcnti
	stop	tcnt
	call	L024C
	orl	p1,#0FFH
	orl	p2,#0FFH
L0244:
	in	a,p2
	jb4	L0244
	in	a,p2
	jb4	L0244
	jmp	initialize
L024C:
	retr
	
; Padding (269-bytes) to align character dot matrix tables at end of ROM
	db	000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H
	db	000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H
	db	000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H
	db	000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H
	db	000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H
	db	000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H
	db	000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H
	db	000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H
	db	000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H
	db	000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H
	db	000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H
	db	000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H
	db	000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H
	db	000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H
	db	000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H
	db	000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H
	db	000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H

;
L035A:
	mov	a,r4
	movp	a,@a
	mov	@r0,a
	inc	r0
	jmp	L045A

; Data (160-bytes)
	db	000H, 000H, 000H, 014H, 024H, 023H, 036H, 000H, 000H, 000H, 012H, 008H, 000H, 008H, 000H, 020H
	db	03EH, 000H, 042H, 021H, 018H, 027H, 03CH, 001H, 036H, 006H, 000H, 000H, 008H, 014H, 000H, 002H
	db	032H, 07CH, 07FH, 03EH, 07FH, 07FH, 07FH, 03EH, 07FH, 000H, 020H, 07FH, 07FH, 07FH, 07FH, 03EH
	db	07FH, 03EH, 07FH, 026H, 001H, 03FH, 01FH, 03FH, 063H, 007H, 061H, 000H, 015H, 000H, 004H, 040H
	db	000H, 024H, 000H, 000H, 038H, 038H, 000H, 008H, 000H, 000H, 020H, 000H, 000H, 07CH, 000H, 038H
	db	07CH, 008H, 000H, 048H, 000H, 000H, 01CH, 03CH, 044H, 00CH, 044H, 000H, 000H, 041H, 002H, 000H
	db	000H, 070H, 000H, 040H, 010H, 000H, 00AH, 004H, 020H, 018H, 048H, 048H, 008H, 040H, 054H, 018H
	db	008H, 001H, 010H, 00EH, 042H, 022H, 042H, 00AH, 008H, 008H, 042H, 002H, 04AH, 042H, 002H, 006H
	db	008H, 00AH, 00EH, 004H, 000H, 044H, 040H, 042H, 022H, 000H, 078H, 03FH, 002H, 004H, 032H, 002H
	db	02AH, 038H, 040H, 00AH, 004H, 040H, 04AH, 004H, 00EH, 07CH, 07EH, 07EH, 00EH, 042H, 002H, 007H

; Padding (90-bytes) to align next page of ROM
	db	000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H
	db	000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H
	db	000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H
	db	000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H
	db	000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H
	db	000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H
;
L045A:
	mov	a,r4
	movp	a,@a
	mov	@r0,a
	inc	r0
	jmp	L055A

; Data (160-bytes)
	db	000H, 000H, 007H, 07FH, 02AH, 013H, 049H, 005H, 01CH, 041H, 00CH, 008H, 050H, 008H, 060H, 010H
	db	051H, 042H, 061H, 041H, 014H, 045H, 04AH, 071H, 049H, 049H, 036H, 056H, 014H, 014H, 041H, 001H
	db	049H, 012H, 049H, 041H, 041H, 049H, 009H, 041H, 008H, 041H, 040H, 008H, 040H, 002H, 004H, 041H
	db	009H, 041H, 009H, 049H, 001H, 040H, 020H, 040H, 014H, 008H, 051H, 07FH, 016H, 041H, 002H, 040H
	db	000H, 054H, 07FH, 038H, 044H, 054H, 004H, 054H, 07FH, 044H, 040H, 07FH, 041H, 004H, 07CH, 044H
	db	014H, 014H, 07CH, 054H, 004H, 03CH, 020H, 040H, 028H, 050H, 064H, 008H, 000H, 041H, 001H, 000H
	db	000H, 050H, 000H, 040H, 020H, 018H, 04AH, 044H, 010H, 008H, 048H, 028H, 07CH, 048H, 054H, 000H
	db	008H, 041H, 008H, 002H, 042H, 012H, 03FH, 00AH, 046H, 007H, 042H, 00FH, 04AH, 022H, 03FH, 048H
	db	046H, 04AH, 000H, 045H, 07FH, 024H, 042H, 02AH, 012H, 040H, 000H, 044H, 042H, 002H, 002H, 012H
	db	02AH, 024H, 028H, 03EH, 07FH, 042H, 04AH, 005H, 040H, 000H, 040H, 042H, 002H, 042H, 004H, 005H

; Padding (90-bytes) to align next page of ROM
	db	000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H
	db	000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H
	db	000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H
	db	000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H
	db	000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H
	db	000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H

;
L055A:
	mov	a,r4
	movp	a,@a
	mov	@r0,a
	inc	r0
	jmp	L065A
	
; Data (160-bytes)
	db	000H, 04FH, 000H, 014H, 07FH, 008H, 055H, 003H, 022H, 022H, 03FH, 03EH, 030H, 008H, 060H, 008H
	db	049H, 07FH, 051H, 045H, 012H, 045H, 049H, 009H, 049H, 049H, 036H, 036H, 022H, 014H, 022H, 051H
	db	079H, 011H, 049H, 041H, 041H, 049H, 009H, 049H, 008H, 07FH, 041H, 014H, 040H, 00CH, 008H, 041H
	db	009H, 051H, 019H, 049H, 07FH, 040H, 040H, 038H, 008H, 070H, 049H, 041H, 07CH, 041H, 001H, 040H
	db	003H, 054H, 044H, 044H, 044H, 054H, 07EH, 054H, 004H, 07DH, 040H, 010H, 07FH, 078H, 004H, 044H
	db	014H, 014H, 008H, 054H, 03FH, 040H, 040H, 030H, 010H, 050H, 054H, 036H, 077H, 036H, 002H, 000H
	db	000H, 070H, 00FH, 070H, 040H, 018H, 02AH, 034H, 078H, 04CH, 078H, 018H, 008H, 048H, 054H, 058H
	db	008H, 03DH, 07CH, 043H, 07EH, 00AH, 002H, 07FH, 042H, 042H, 042H, 042H, 040H, 012H, 042H, 040H
	db	04AH, 03EH, 04EH, 03DH, 008H, 01FH, 042H, 012H, 07FH, 020H, 002H, 044H, 042H, 004H, 07FH, 022H
	db	02AH, 022H, 010H, 04AH, 004H, 042H, 04AH, 045H, 020H, 07EH, 020H, 042H, 042H, 040H, 001H, 007H

; Padding (90-bytes) to align next page of ROM
	db	000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H
	db	000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H
	db	000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H
	db	000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H
	db	000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H
	db	000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H

;
L065A:
	mov	a,r4
	movp	a,@a
	mov	@r0,a
	inc	r0
	jmp	L075A
	
; Data (160-bytes)
	db	000H, 000H, 007H, 07FH, 02AH, 064H, 022H, 000H, 041H, 01CH, 00CH, 008H, 000H, 008H, 000H, 004H
	db	045H, 040H, 049H, 04BH, 07FH, 045H, 049H, 005H, 049H, 029H, 000H, 000H, 041H, 014H, 014H, 009H
	db	041H, 012H, 049H, 041H, 022H, 049H, 009H, 049H, 008H, 041H, 03FH, 022H, 040H, 002H, 010H, 041H
	db	009H, 021H, 029H, 049H, 001H, 040H, 020H, 040H, 014H, 008H, 045H, 041H, 016H, 07FH, 002H, 040H
	db	005H, 078H, 044H, 044H, 07FH, 054H, 005H, 054H, 004H, 040H, 03DH, 028H, 040H, 004H, 004H, 044H
	db	014H, 014H, 004H, 054H, 044H, 040H, 020H, 040H, 028H, 03CH, 04CH, 041H, 000H, 008H, 004H, 000H
	db	000H, 000H, 001H, 000H, 000H, 000H, 01AH, 014H, 004H, 048H, 048H, 07CH, 028H, 078H, 07CH, 040H
	db	008H, 009H, 002H, 022H, 042H, 07FH, 042H, 00AH, 022H, 03EH, 042H, 03FH, 020H, 02AH, 04AH, 020H
	db	032H, 009H, 020H, 005H, 010H, 004H, 042H, 02AH, 00EH, 01FH, 004H, 044H, 022H, 008H, 002H, 052H
	db	02AH, 020H, 028H, 04AH, 014H, 07EH, 04AH, 025H, 01EH, 040H, 018H, 042H, 022H, 020H, 002H, 000H

; Padding (90-bytes) to align next page of ROM
	db	000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H
	db	000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H
	db	000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H
	db	000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H
	db	000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H
	db	000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H

; Get character data from ROM
L075A:
	mov	a,r4	; load data byte
	movp	a,@a	; load A from ROM current page
	mov	@r0,a	; store A to @R0
	jmp	L014D	; jump

; Data (160-bytes)
	db	000H, 000H, 000H, 000H, 014H, 012H, 062H, 050H, 000H, 000H, 000H, 012H, 008H, 000H, 008H, 000H
	db	002H, 03EH, 000H, 046H, 031H, 010H, 039H, 030H, 003H, 036H, 01EH, 000H, 000H, 000H, 014H, 008H
	db	006H, 03EH, 07CH, 036H, 022H, 01CH, 041H, 001H, 07AH, 07FH, 000H, 001H, 041H, 040H, 07FH, 07FH
	db	03EH, 006H, 05EH, 046H, 032H, 001H, 03FH, 01FH, 03FH, 063H, 007H, 043H, 000H, 015H, 000H, 004H
	db	040H, 000H, 040H, 038H, 044H, 000H, 058H, 005H, 03CH, 078H, 000H, 000H, 044H, 000H, 078H, 078H
	db	038H, 008H, 07CH, 004H, 024H, 040H, 07CH, 01CH, 03CH, 044H, 000H, 044H, 041H, 000H, 000H, 002H
	db	000H, 000H, 000H, 001H, 000H, 000H, 000H, 00EH, 00CH, 000H, 038H, 048H, 008H, 018H, 040H, 000H
	db	038H, 008H, 007H, 001H, 01EH, 042H, 002H, 03EH, 00AH, 01EH, 002H, 07EH, 002H, 01CH, 046H, 046H
	db	01EH, 01EH, 008H, 01EH, 004H, 000H, 004H, 040H, 006H, 012H, 000H, 078H, 044H, 01EH, 030H, 032H
	db	00EH, 040H, 070H, 046H, 04AH, 00CH, 040H, 07EH, 01CH, 000H, 038H, 000H, 07EH, 01EH, 018H, 000H
	
; End of ROM (07FFH)
	db	000H
