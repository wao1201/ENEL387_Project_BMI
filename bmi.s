; ENEL 387 Project - BMI Indicator 
; Wei Wang, April 02, 2013
;; Directives
		PRESERVE8
		THUMB
;;;Equates
INITIAL_MSP 	EQU	0x20001000	
;PORT C GPIO-BASE Addr: 0x40011000
GPIOC_CRL   EQU	0x40011000
GPIOC_CRH	EQU	0x40011004
GPIOC_IDR	EQU	0x40011008
GPIOC_ODR	EQU	0x4001100C
GPIOC_BSRR	EQU	0x40011010
GPIOC_BRR	EQU	0x40011014
GPIOC_LCKR	EQU	0x40011018
;Port B
GPIOB_CRL   EQU	0x40010C00
GPIOB_CRH	EQU	0x40010C04
GPIOB_IDR	EQU	0x40010C08
GPIOB_ODR	EQU	0x40010C0C
GPIOB_BSRR	EQU	0x40010C10
GPIOB_BRR	EQU	0x40010C14
GPIOB_LCKR	EQU	0x40010C18
;Port A
GPIOA_CRL   EQU	0x40010800
GPIOA_CRH	EQU	0x40010804
GPIOA_IDR	EQU	0x40010808
GPIOA_ODR	EQU	0x4001080C
GPIOA_BSRR	EQU	0x40010810
GPIOA_BRR	EQU	0x40011084
GPIOA_LCKR	EQU	0x40011088
;Clock
RCC_APB2ENR	EQU	0x40021018
;LCD Control Bit Patterns
LCD_8B2L	EQU	0x38
LCD_DCB		EQU	0x0F
LCD_MCR		EQU	0x06
LCD_CLR		EQU	0x01
LCD_LN1		EQU	0x80
LCD_LN2		EQU	0xC0
LCD_LN3		EQU 0x94
LCD_LN4		EQU 0xD4
LCD_CM_ENA	EQU	0x00020001
LCD_CM_DIS	EQU	0x00030000
LCD_DM_ENA	EQU	0x00000003
LCD_DM_DIS	EQU	0x00010002
;Analog to Digital Converter
ADC_SR      EQU 0x40012400
ADC_CR1     EQU 0x40012404
ADC_CR2     EQU 0x40012408
ADC_SMPR1   EQU 0x4001240C
ADC_SMPR2   EQU 0x40012410
ADC_JOFR1   EQU 0x40012414
ADC_JOFR2   EQU 0x40012418
ADC_JOFR3   EQU 0x4001241C
ADC_JOFR4   EQU 0x40012420
ADC_HTR     EQU 0x40012424
ADC_LTR     EQU 0x40012428
ADC_SQR1    EQU 0x4001242C
ADC_SQR2    EQU 0x40012430
ADC_SQR3    EQU 0x40012434
ADC_JSQR    EQU 0x40012438
ADC_JDR1    EQU 0x4001243C
ADC_JDR2    EQU 0x40012440
ADC_JDR3    EQU 0x40012444
ADC_JDR4    EQU 0x40012448
ADC_DR      EQU 0x4001244C
;Delay Time
DELAYTIME1   EQU          1000000
DELAYTIME2   EQU          10000
DELAYTIME3   EQU          350000
;=========================================================
		AREA  RESET,Data,READONLY
		EXPORT __Vectors
__Vectors
		DCD	INITIAL_MSP
		DCD	Reset_Handler
		DCD	nmi_ISR
		DCD	h_fault_ISR
		DCD	m_fault_ISR
		DCD	b_fault_ISR
		DCD	u_fault_ISR
			
		AREA   MYCODE,CODE,READONLY
		EXPORT	   Reset_Handler
		ENTRY
;===========================================================
Reset_Handler	PROC
;initialize the clock
clock_init
		ldr	R6,=RCC_APB2ENR
		mov	R0,#0x021C
		str	R0,[R6]
;open ports for the components
gpio_init
		;open port A for ADC and sensors' inputs
		ldr		R6,=GPIOA_CRL
		ldr 	R0,=0x04444404	;open ports 1 and 7 for input
		str 	R0,[R6]
		str 	R0,[R6]
		ldr		R6,=GPIOA_CRH
		ldr 	R0,=0x44444333	;open ports 8-10 for output
		str 	R0,[R6]
		str 	R0,[R6]
		
		;open port B
		ldr		R6,=GPIOB_CRL
		ldr		R0,=0X34444433	;open ports 0,1,and 7
		str		R0,[R6]
		
		;open port C
		ldr		R6,=GPIOC_CRL		
		ldr		R0,=0X33333333	
		str		R0,[R6]
		
		mov		R2,#0X0100
		mov		R3,#0x0200

		ALIGN
		ENDP
;===================================================
;initialize the LCD
lcd_init	PROC
		ldr		R0,=LCD_8B2L
		bl		cmd2lcd
			
		ldr		R0,=LCD_8B2L
		bl		cmd2lcd
		
		ldr		R0,=LCD_8B2L
		bl		cmd2lcd
		
		ldr		R0,=LCD_8B2L
		bl		cmd2lcd
			
		ldr		R0,=LCD_DCB
		bl		cmd2lcd
			
		ldr		R0,=LCD_CLR
		bl		cmd2lcd
			
		ldr		R0,=LCD_MCR
		bl		cmd2lcd
	
		ALIGN
		ENDP
;=========================================================
ledOFF
		ldr		R6,=GPIOA_BSRR	;turn off leds at beginning
		ldr		R0,=0x07000000
		str		R0,[R6]
;=======================================================
;function for user to stand on the plate and get ready for measure
greetinginfo
		ldr		R6,=greeting
		LDR		R0,=LCD_LN1
		BL		cmd2lcd
showgreet
		ldrb	R0,[R6],#1
		cmp		R0,#0
		beq		heightP1
		bl		data2lcdSHOW	;long delay time, means the user get enough time to be ready
		b		showgreet
;=============================================================
;analog to digital converter and display information
;for height
heightP1
		LDR		R6,=ADC_CR2
		LDR		R0,=0X01
		STR		R0,[R6]			
		LDR		R6,=ADC_SMPR2
		LDR		R0,=0X00fC0000
		LDR		R0,[R6]

		LDR		R6,=ADC_SQR3	;pa1
		LDR		R0,=0X01
		STR		R0,[R6]

		LDR		R6,=ADC_CR2
		LDR		R0,=0X01
		STR		R0,[R6]

		LDR		R0,=LCD_LN1		;enable line1 on LCD
		BL		cmd2lcd
		
		ldr		R6,=line1info ;load string
line1	
		ldrb	R0,[R6],#1	;this part display the predefined menu for height
		cmp		R0,#0
		beq		heightP2
		bl		data2lcd
		b		line1
		
		LTORG
heightP2
		bl		check	;jump to adc check function
		bl		displayH	;jump to function for converting and displaying height-hex to decimal
;-------------------------------------------------------------
;for weight
weightP1
		LDR		R6,=ADC_CR2
		LDR		R0,=0X01
		STR		R0,[R6]			
		LDR		R6,=ADC_SMPR2
		LDR		R0,=0X00fC0000
		LDR		R0,[R6]
		
		LDR		R6,=ADC_SQR3	;pa7
		LDR		R0,=0X07
		STR		R0,[R6]

		LDR		R6,=ADC_CR2
		LDR		R0,=0X01
		STR		R0,[R6]

		LDR		R0,=LCD_LN2	;enable line2 on LCD
		BL		cmd2lcd
		
		ldr		R6,=line2info  ;load string
line2
		ldrb	R0,[R6],#1	;this part display the predefined menu for weight
		cmp		R0,#0
		beq		weightP2
		bl		data2lcd
		b		line2

weightP2
		bl		check ;jump to adc check function
		bl		displayW  ;jump to function for converting and displaying weight-hex to decimal
;-----------------------------------------------------
;for BMI
bmiP1
		LDR		R0,=LCD_LN3	;enable line3 on LCD
		BL		cmd2lcd
		
		ldr		R6,=line3info ;load string
line3	
		ldrb	R0,[R6],#1	;this part display the predefined menu for BMI
		cmp		R0,#0
		beq		bmiP2
		bl		data2lcd
		b		line3
bmiP2
		bl		displayBMI  ;jump to function for converting and displaying BMI-hex to decimal
;------------------------------------------------------
;for LED alert
showAdvice
		LDR		R0,=LCD_LN4	;enable line3 on LCD
		BL		cmd2lcd
		
		;If bmi is less or equal to 18, go to function: displayRED1
		;r8 stores the calculated bmi value
		ldr		r1,=0x12	;bmi: 18
		cmp		r8,r1
		IT		LE
		BLE		displayRED1
		
		;If bmi is less than 25, go to function: displayBLUE
		ldr		r1,=0x19	;bmi: 25
		cmp		r8,r1
		IT		LT
		BLT		displayBLUE
		
		;If bmi is less than 30, go to function: displayYELLOW
		ldr		r1,=0x1E	;bmi: 30
		cmp		r8,r1
		IT		LT
		BLT		displayYELLOW
		
		;If bmi is great or equal to 30, go to function: displayRED2
		ldr		r1,=0x1E	;bmi: 30
		cmp		r8,r1
		IT		GE
		BGE		displayRED2		
;------------------------------------------------------
loop	;this loop is for keeping the information on LCD, so the user can easily read
		b		loop
;=================================================
;convert hex number to decimal, and display
displayH		PROC
		push	{lr}
		LDR		R6,=ADC_DR		;READ DATA
		ldr		r0,[r6]		;load the adc_value to r0
		
;hard coded part for determining the height (theory:200cm - measured distance)
;I set up 19 points based on the output chracteristic of the sensor, 185cm to 140cm
;If the adc_value is in a certain range, the corresponing display function would be called
		;point 1
		ldr		r1,=0xEAC
		cmp		r0,r1		;compare with 3756
		IT		GE			;if greater or equal
		bge		display185
		;point 2
		ldr		r1,=0xE02
		cmp		r0,r1		;compare with 3586
		IT		GE			;if greater or equal
		bge		display183
		;point 3
		ldr		r1,=0xD57
		cmp		r0,r1		;compare with 3415
		IT		GE			;if greater or equal
		bge		display180
		;point 4
		ldr		r1,=0xCAC
		cmp		r0,r1		;compare with 3244
		IT		GE			;if greater or equal
		bge		display177
		;point 5
		ldr		r1,=0xC01
		cmp		r0,r1		;compare with 3073
		IT		GE			;if greater or equal
		bge		display175
		;point 6
		ldr		r1,=0xB57
		cmp		r0,r1		;compare with 2903
		IT		GE			;if greater or equal
		bge		display173
		;point 7
		ldr		r1,=0xAAC
		cmp		r0,r1		;compare with 2732
		IT		GE			;if greater or equal
		bge		display170
		;point 8
		ldr		r1,=0xA01
		cmp		r0,r1		;compare with 2561
		IT		GE			;if greater or equal
		bge		display167
		;point 9
		ldr		r1,=0x957
		cmp		r0,r1		;compare with 2391
		IT		GE			;if greater or equal
		bge		display165
		;point 10
		ldr		r1,=0x8AC
		cmp		r0,r1		;compare with 2220
		IT		GE			;if greater or equal
		bge		display163
		;point 11
		ldr		r1,=0x845
		cmp		r0,r1		;compare with 2117
		IT		GE			;if greater or equal
		bge		display160
		;point 12
		ldr		r1,=0x7AC
		cmp		r0,r1		;compare with 1964
		IT		GE			;if greater or equal
		bge		display157
		;point 13
		ldr		r1,=0x778
		cmp		r0,r1		;compare with 1912
		IT		GE			;if greater or equal
		bge		display155
		;point 14
		ldr		r1,=0x712
		cmp		r0,r1		;compare with 1810
		IT		GE			;if greater or equal
		bge		display153
		;point 15
		ldr		r1,=0x6AB
		cmp		r0,r1		;compare with 1707
		IT		GE			;if greater or equal
		bge		display150
		;point 16
		ldr		r1,=0x678
		cmp		r0,r1		;compare with 1656
		IT		GE			;if greater or equal
		bge		display147
		;point 17
		ldr		r1,=0x645
		cmp		r0,r1		;compare with 1605
		IT		GE			;if greater or equal
		bge		display145
		;point 18
		ldr		r1,=0x612
		cmp		r0,r1		;compare with 1554
		IT		GE			;if greater or equal
		bge		display143
		;point 19
		ldr		r1,=0x5DE
		cmp		r0,r1		;compare with 1502
		IT		GE			;if greater or equal
		bge		display140
		
		pop		{pc}
		ENDP
;---------------------------------------------------------------
displayW		PROC
		push	{lr}
		LDR		R6,=ADC_DR		;READ DATA
		ldr		r2,[r6]		;load adc_value to r2
		
;The largest voltage is 3.3V because of the Discovery board, so the maximum value we can get is 36kg
;according to the datasheet. Then, my value is adc_value/114. The 114 is computed by 4096/36
		ldr		r5,=0x72	;r5=114
		sdiv	r2,r5		;r2=r5/114, so get the weight
		
		mov		r7,r2		;save r2 for bmi

		ldr 	r1,=0xa       ;r1=10
		sdiv 	r3,r2,r1
		add  	r0,r3,#0x30		
		BL		data2lcd
		
		mul 	r0,r1,r3    
		sub 	r2,r0      
		mov  	r0,r2
		add  	r0,r0,#0x30		
		BL		data2lcd
		
		pop		{pc}
		ENDP
	LTORG
;------------------------------------------------------
displayBMI		PROC
		push	{lr}
		
		ldr		r5,=0x64	;cm to m
		sdiv	r4,r4,r5
		mul		r4,r4,r4	;H_square=H*H
		sdiv	r7,r7,r4	;BMI=W/H_square
		
		mov		r8,r7	;copy r7 to r8 for function showAdvice
		
		;convert the hex to decimal(for display purpose)
		;for the "10" position
		ldr 	r1,=0xa       ;r1=10
		sdiv 	r3,r7,r1
		add  	r0,r3,#0x30	;for corresponding ascii code
		BL		data2lcd
		;for "1" position
		mul 	r0,r1,r3    
		sub 	r7,r0      
		mov  	r0,r2
		add  	r0,r0,#0x30	;for corresponding ascii code
		BL		data2lcd

		pop		{pc}
		ENDP
;------------------------------------------
;Use 200cm as base, H=200-ir_value
;19 sub functions for display predefined height
display185	;185
		push	{lr}
		LDR		R4,=0xB9	;185
		LDR   	R0,=0x31   ;ASCII: 1
		BL		data2lcd
		LDR   	R0,=0x38   ;ASCII: 8
		BL		data2lcd
		LDR   	R0,=0x35   ;ASCII: 5
		BL		data2lcd
		pop		{pc}
		
display183	;183
		push	{lr}
		LDR		R4,=0xB7	;183
		LDR   	R0,=0x31   ;ASCII: 1
		BL		data2lcd
		LDR   	R0,=0x38   ;ASCII: 8
		BL		data2lcd
		LDR   	R0,=0x33   ;ASCII: 3
		BL		data2lcd
		pop		{pc}
		
display180	;180
		push	{lr}
		LDR		R4,=0xB4	;180
		LDR   	R0,=0x31   ;ASCII: 1
		BL		data2lcd
		LDR   	R0,=0x38   ;ASCII: 8
		BL		data2lcd
		LDR   	R0,=0x30   ;ASCII: 0
		BL		data2lcd
		pop		{pc}
		
display177	;177
		push	{lr}
		LDR		R4,=0xB1	;177
		LDR   	R0,=0x31   ;ASCII: 1
		BL		data2lcd
		LDR   	R0,=0x37   ;ASCII: 7
		BL		data2lcd
		LDR   	R0,=0x37   ;ASCII: 7
		BL		data2lcd
		pop		{pc}
		
display175	;175
		push	{lr}
		LDR		R4,=0xAF	;175
		LDR   	R0,=0x31   ;ASCII: 1
		BL		data2lcd
		LDR   	R0,=0x37   ;ASCII: 7
		BL		data2lcd
		LDR   	R0,=0x35   ;ASCII: 5
		BL		data2lcd
		pop		{pc}
		
display173	;173
		push	{lr}
		LDR		R4,=0xAD	;173
		LDR   	R0,=0x31   ;ASCII: 1
		BL		data2lcd
		LDR   	R0,=0x37   ;ASCII: 7
		BL		data2lcd
		LDR   	R0,=0x33   ;ASCII: 3
		BL		data2lcd
		pop		{pc}
		
display170	;170
		push	{lr}
		LDR		R4,=0xAA	;170
		LDR   	R0,=0x31   ;ASCII: 1
		BL		data2lcd
		LDR   	R0,=0x37   ;ASCII: 7
		BL		data2lcd
		LDR   	R0,=0x30   ;ASCII: 0
		BL		data2lcd
		pop		{pc}
		
display167	;167
		push	{lr}
		LDR		R4,=0xA7	;167
		LDR   	R0,=0x31   ;ASCII: 1
		BL		data2lcd
		LDR   	R0,=0x36   ;ASCII: 6
		BL		data2lcd
		LDR   	R0,=0x37   ;ASCII: 7
		BL		data2lcd
		pop		{pc}
		
display165	;165
		push	{lr}
		LDR		R4,=0xA5	;165
		LDR   	R0,=0x31   ;ASCII: 1
		BL		data2lcd
		LDR   	R0,=0x36   ;ASCII: 6
		BL		data2lcd
		LDR   	R0,=0x35   ;ASCII: 5
		BL		data2lcd
		pop		{pc}
		
display163	;163
		push	{lr}
		LDR		R4,=0xA3	;163
		LDR   	R0,=0x31   ;ASCII: 1
		BL		data2lcd
		LDR   	R0,=0x36   ;ASCII: 6
		BL		data2lcd
		LDR   	R0,=0x33   ;ASCII: 3
		BL		data2lcd
		pop		{pc}
		
display160	;160
		push	{lr}
		LDR		R4,=0xA0	;160
		LDR   	R0,=0x31   ;ASCII: 1
		BL		data2lcd
		LDR   	R0,=0x36   ;ASCII: 6
		BL		data2lcd
		LDR   	R0,=0x30   ;ASCII: 0
		BL		data2lcd
		pop		{pc}
		
display157	;157
		push	{lr}
		LDR		R4,=0x9D	;157
		LDR   	R0,=0x31   ;ASCII: 1
		BL		data2lcd
		LDR   	R0,=0x35   ;ASCII: 5
		BL		data2lcd
		LDR   	R0,=0x37   ;ASCII: 7
		BL		data2lcd
		pop		{pc}
		
display155	;155
		push	{lr}
		LDR		R4,=0x9B	;155
		LDR   	R0,=0x31   ;ASCII: 1
		BL		data2lcd
		LDR   	R0,=0x35   ;ASCII: 5
		BL		data2lcd
		LDR   	R0,=0x35   ;ASCII: 5
		BL		data2lcd
		pop		{pc}
		
display153	;153
		push	{lr}
		LDR		R4,=0x99	;153
		LDR   	R0,=0x31   ;ASCII: 1
		BL		data2lcd
		LDR   	R0,=0x35   ;ASCII: 5
		BL		data2lcd
		LDR   	R0,=0x33   ;ASCII: 3
		BL		data2lcd
		pop		{pc}
		
display150	;150
		push	{lr}
		LDR		R4,=0x96	;150
		LDR   	R0,=0x31   ;ASCII: 1
		BL		data2lcd
		LDR   	R0,=0x35   ;ASCII: 5
		BL		data2lcd
		LDR   	R0,=0x30   ;ASCII: 0
		BL		data2lcd
		pop		{pc}
		
display147	;147
		push	{lr}
		LDR		R4,=0x93	;147
		LDR   	R0,=0x31   ;ASCII: 1
		BL		data2lcd
		LDR   	R0,=0x34   ;ASCII: 4
		BL		data2lcd
		LDR   	R0,=0x37   ;ASCII: 7
		BL		data2lcd
		pop		{pc}
		
display145	;145
		push	{lr}
		LDR		R4,=0x91	;145
		LDR   	R0,=0x31   ;ASCII: 1
		BL		data2lcd
		LDR   	R0,=0x34   ;ASCII: 4
		BL		data2lcd
		LDR   	R0,=0x35   ;ASCII: 5
		BL		data2lcd
		pop		{pc}
		
display143	;143
		push	{lr}
		LDR		R4,=0x8F	;143
		LDR   	R0,=0x31   ;ASCII: 1
		BL		data2lcd
		LDR   	R0,=0x34   ;ASCII: 4
		BL		data2lcd
		LDR   	R0,=0x33   ;ASCII: 3
		BL		data2lcd
		pop		{pc}
		
display140	;140
		push	{lr}
		LDR		R4,=0x8C	;140
		LDR   	R0,=0x31   ;ASCII: 1
		BL		data2lcd
		LDR   	R0,=0x34   ;ASCII: 4
		BL		data2lcd
		LDR   	R0,=0x30   ;ASCII: 0
		BL		data2lcd
		pop		{pc}
;-----------------------------------------------------
;sub functions for displaying corresponding LED, based on BMI
displayRED1
		ldr		R6,=redadvice1		
red1	
		ldrb	R0,[R6],#1
		cmp		R0,#0
		beq		red1back
		bl		data2lcd		
		b		red1
red1back
		ldr		R6,=GPIOA_BSRR	;turn on red led
		ldr		R0,=0x00000100
		str		R0,[R6]
		bl		showAdvice
;----------------------------------
displayBLUE
		ldr		R6,=blueadvice		
blue	
		ldrb	R0,[R6],#1	;function for displaing corresponding string
		cmp		R0,#0
		beq		blueback
		bl		data2lcd
		b		blue
blueback
		ldr		R6,=GPIOA_BSRR  ;turn on blue led
		ldr		R0,=0x00000400
		str		R0,[R6]
		bl		showAdvice
;------------------------------------------		
displayRED2
		ldr		R6,=redadvice2		
red2	
		ldrb	R0,[R6],#1 ;function for displaing corresponding string
		cmp		R0,#0
		beq		red2back
		bl		data2lcd
		b		red2
red2back
		ldr		R6,=GPIOA_BSRR	;turn on red led
		ldr		R0,=0x00000100
		str		R0,[R6]
		bl		showAdvice
;---------------------------------------------------
displayYELLOW
		ldr		R6,=yellowadvice		
yellow	
		ldrb	R0,[R6],#1 ;function for displaing corresponding string
		cmp		R0,#0
		beq		yellowback
		bl		data2lcd
		b		yellow
yellowback
		ldr		R6,=GPIOA_BSRR	;turn on yellow led
		ldr		R0,=0x00000200
		str		R0,[R6]
		bl		showAdvice
;======================================================
;adc checking function
check
		LDR		R6,=ADC_SR			;CHECK THE BIT
		LDR		R0,[R6]
		AND		R0,R0,#0X02
		CMP		R0,#0X02				;check the bit
		BNE		check
		bx		LR
;==============================================================
;functions for command to LCD and Data to LCD
cmd2lcd	PROC
		push	{R0,R1,R6,LR}
		
		ldr		R6,=GPIOB_BSRR
		ldr 	R0,=LCD_CM_ENA
		str 	R0,[R6]
		
		pop 	{R0}
		ldr 	R6,=GPIOC_ODR
		str 	R0,[R6]
		
		ldr 	R1,=DELAYTIME2
		bl		delay
		
		ldr 	R6,=GPIOB_BSRR
		ldr 	R0,=LCD_CM_DIS
		str 	R0,[R6]
		
		ldr 	R1,=DELAYTIME2
		bl		delay
		
		pop 	{R1,R6,PC}
		ENDP
;---------------------------------------		
data2lcd	PROC	
		PUSH	{R0,R1,R6,LR}
		ldr 	R6,= GPIOB_BSRR	
		ldr		R0, = LCD_DM_ENA	
		str		R0,[R6]
			
		POP		{R0}
			
		ldr		R6,= GPIOC_ODR
		STR		R0,[R6]
			
		ldr		R1, = DELAYTIME2
		bl 		delay
			
		ldr		R6,= GPIOB_BSRR
		ldr		R0,=LCD_DM_DIS
		STR		R0,[R6]
			
		ldr		R1,= DELAYTIME2
		bl 		delay
			
		POP		{R1, R6, PC}
		ENDP
;-----------------------------------------
;this function uses a longer delay time
data2lcdSHOW	PROC	
		PUSH	{R0,R1,R6,LR}
		ldr 	R6,= GPIOB_BSRR	
		ldr		R0, = LCD_DM_ENA	
		str		R0,[R6]
			
		POP		{R0}
			
		ldr		R6,= GPIOC_ODR
		STR		R0,[R6]
			
		ldr		R1, = DELAYTIME1
		bl 		delay
			
		ldr		R6,= GPIOB_BSRR
		ldr		R0,=LCD_DM_DIS
		STR		R0,[R6]
			
		ldr		R1,= DELAYTIME1
		bl 		delay
			
		POP		{R1, R6, PC}
		ENDP
;============================================
;delay funtion
delay	PROC	
		subs	R1,#1
		bne		delay	
		bx		LR
		
		ALIGN
		ENDP
;==========================================
;predefined strings
		ALIGN
line1info		DCB "Your Height(cm):",00
line2info		DCB "Your Weight(kg):",00
line3info		DCB "  Your   BMI   :",00
redadvice1		DCB "Please Eat More!",00
redadvice2		DCB "Go to Gym, NOW!",00
yellowadvice	DCB "You Need Exercise!",00
blueadvice		DCB "Keep It This Way!",00
greeting		DCB "Loading...",00
		ALIGN
;=====================================================
		AREA  HANDLERS,CODE,READONLY
nmi_ISR
		b	.
h_fault_ISR
		b	.
m_fault_ISR
		b	.
b_fault_ISR	
		b	.
u_fault_ISR	
		b	.
	
		ALIGN
		END		   	