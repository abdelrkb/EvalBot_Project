;; RK - Evalbot (Cortex M3 de Texas Instrument)
; Bibliothèque - Configuration et pilotage des moteurs par PWM

;; Références datasheet lm3s9b92.pdf
;; Câblage moteurs :
; Moteur Droit (Port D) :
;   - PD0 (PWM0) => PWM du pont en H DRV8801RT
;   - PD1 => Phase/Direction
;   - PD2 => SlowDecay commun
;   - PD5 => Enable 12V
; Moteur Gauche (Port H) :
;   - PH0 (PWM2) => PWM du 2ème pont en H
;   - PH1 => Phase/Direction

;; Masques GPIO
GPIO_0		EQU		0x1
GPIO_1		EQU		0x2
GPIO_2		EQU		0x4
GPIO_5		EQU		0x20

;; Registres horloge système
SYSCTL_RCGC0	EQU		0x400FE100	; p271 - horloge PWM
SYSCTL_RCGC2	EQU		0x400FE108	; p291 - horloge GPIO

;; Configuration GPIO Port D
PORTD_BASE		EQU		0x40007000
GPIODATA_D		EQU		PORTD_BASE
GPIODIR_D		EQU		PORTD_BASE+0x00000400
GPIODR2R_D		EQU		PORTD_BASE+0x00000500
GPIODEN_D		EQU		PORTD_BASE+0x0000051C
GPIOPCTL_D		EQU		PORTD_BASE+0x0000052C	; p444 - multiplexage
GPIOAFSEL_D		EQU		PORTD_BASE+0x00000420	; p426 - fonction alternative

;; Configuration GPIO Port H
PORTH_BASE		EQU		0x40027000
GPIODATA_H		EQU		PORTH_BASE
GPIODIR_H		EQU		PORTH_BASE+0x00000400
GPIODR2R_H		EQU		PORTH_BASE+0x00000500
GPIODEN_H		EQU		PORTH_BASE+0x0000051C
GPIOPCTL_H		EQU		PORTH_BASE+0x0000052C
GPIOAFSEL_H		EQU		PORTH_BASE+0x00000420

;; Configuration PWM
PWM_BASE		EQU		0x040028000	; p1138
PWMENABLE		EQU		PWM_BASE+0x008	; p1145

; Block PWM0 (génère PWM0 et PWM1 - moteur droit)
PWM0CTL			EQU		PWM_BASE+0x040	; p1167
PWM0LOAD		EQU		PWM_BASE+0x050
PWM0CMPA		EQU		PWM_BASE+0x058
PWM0CMPB		EQU		PWM_BASE+0x05C
PWM0GENA		EQU		PWM_BASE+0x060
PWM0GENB		EQU		PWM_BASE+0x064

; Block PWM1 (génère PWM2 et PWM3 - moteur gauche)
PWM1CTL			EQU		PWM_BASE+0x080
PWM1LOAD		EQU		PWM_BASE+0x090
PWM1CMPA		EQU		PWM_BASE+0x098
PWM1CMPB		EQU		PWM_BASE+0x09C
PWM1GENA		EQU		PWM_BASE+0x0A0
PWM1GENB		EQU		PWM_BASE+0x0A4

VITESSE			EQU		0x1A2	; Rapport cyclique (valeur plus grande = vitesse plus lente)
						
		AREA    |.text|, CODE, READONLY
		ENTRY
		
		;; Fonctions exportées
		EXPORT	MOTEUR_INIT
		EXPORT	MOTEUR_DROIT_ON
		EXPORT  MOTEUR_DROIT_OFF
		EXPORT  MOTEUR_DROIT_AVANT
		EXPORT  MOTEUR_DROIT_ARRIERE
		EXPORT  MOTEUR_DROIT_INVERSE	
		EXPORT	MOTEUR_GAUCHE_ON
		EXPORT  MOTEUR_GAUCHE_OFF
		EXPORT  MOTEUR_GAUCHE_AVANT
		EXPORT  MOTEUR_GAUCHE_ARRIERE
		EXPORT  MOTEUR_GAUCHE_INVERSE

;--------------------------------------------------
; Initialisation complète des moteurs
;--------------------------------------------------
MOTEUR_INIT	
		; Activer l'horloge PWM (bit 20, p271)
		ldr r6, = SYSCTL_RCGC0
		ldr	r0, [R6]
        ORR	r0, r0, #0x00100000
        str r0, [r6]
	
  	; Activer l'horloge Port D (moteur droit)
		ldr r6, = SYSCTL_RCGC2
		ldr	r0, [R6] 		
        ORR	r0, r0, #0x08		; Bit 3 = Port D
        str r0, [r6]

	; Activer l'horloge Port H (moteur gauche)
		ldr r6, = SYSCTL_RCGC2
		ldr	r0, [R6] 
        ORR	r0, r0, #0x80		; Bit 7 = Port H
        str r0, [r6] 
		
		nop				; Attendre stabilisation horloge
		nop
		nop
	 
	; Multiplexage Port D : PD0 = PWM0 (p444, p1261)
		ldr r6, = GPIOPCTL_D
		mov	r0, #0x01		; Mux = 1 pour PWM
        str r0, [r6]
		
	; Multiplexage Port H : PH0 = PWM2
		ldr r6, = GPIOPCTL_H 
		mov	r0, #0x02		; Mux = 2 pour PWM
        str r0, [r6]
		
	; Activer fonction alternative PD0 (p426)
		ldr r6, = GPIOAFSEL_D
		ldr	r0, [R6]
        ORR	r0, r0, #0x01
        str r0, [r6]

	; Activer fonction alternative PH0
		ldr r6, = GPIOAFSEL_H
		ldr	r0, [R6]
        ORR	r0, r0, #0x01
        str r0, [r6]
	
	;--------------------------------------------------
	; Configuration PWM0 (moteur droit)
	;--------------------------------------------------
	; Mode up-down pour signal symétrique
		ldr r6, = PWM0CTL
		mov	r0, #2
        str r0, [r6]	
		
	; Générateur A : sortie PWM selon comparateur
		ldr r6, =PWM0GENA
		mov	r0,	#0x0B0		; En down: PWM low, en up: PWM high
		str r0, [r6]
		
		ldr r6, =PWM0GENB
		mov	r0,	#0x0B00
		str r0, [r6]
		
	; Période du signal PWM
		ldr	r6, =PWM0LOAD
		mov r0,	#0x1F4		; Période/2 = 500
		str	r0,[r6]
		
	; Rapport cyclique (vitesse)
		ldr	r6, =PWM0CMPA
		mov	r0, #VITESSE
		str	r0, [r6]
		
		ldr	r6, =PWM0CMPB
		mov	r0,	#0x1F4
		str	r0,	[r6]
		
	; Activer le générateur PWM0
		ldr	r6, =PWM0CTL 
		ldr	r0, [r6]	
		ORR	r0,	r0,	#0x07
		str	r0,	[r6]

	;--------------------------------------------------
	; Configuration PWM1 (moteur gauche)
	;--------------------------------------------------
		ldr r6, = PWM1CTL
		mov	r0, #2
        str r0, [r6]
		
		ldr r6, =PWM1GENA
		mov	r0,	#0x0B0
		str r0, [r6]
		
 		ldr r6, =PWM1GENB
		mov	r0,	#0x0B00
		str r0, [r6]
		
		ldr	r6, =PWM1LOAD
		mov r0,	#0x1F4
		str	r0,[r6]
		
		ldr	r6, =PWM1CMPA
		mov	r0,	#VITESSE
		str	r0, [r6]
		
		ldr	r6, =PWM1CMPB
		mov	r0,	#0x1F4
		str	r0,	[r6]
		
	; Activer le générateur PWM1
		ldr	r6, =PWM1CTL 
		ldr	r0, [r6]
		ORR	r0,	r0,	#0x07
		str	r0,	[r6]		
		
	;--------------------------------------------------
	; Configuration GPIO Port D en sortie
	;--------------------------------------------------
		ldr	r6, =GPIODIR_D 
		ldr	r0, [r6]
		ORR	r0,	#(GPIO_0+GPIO_1+GPIO_2+GPIO_5)
		str	r0,[r6]
		
		ldr	r6, =GPIODR2R_D
		ldr	r0, [r6]
		ORR	r0,	#(GPIO_0+GPIO_1+GPIO_2+GPIO_5)
		str	r0,[r6]
		
		ldr	r6, =GPIODEN_D
		ldr	r0, [r6]
		ORR	r0,	#(GPIO_0+GPIO_1+GPIO_2+GPIO_5)	
		str	r0,[r6]
		
	; État initial : SlowDecay et 12V activés
		ldr	r6, =(GPIODATA_D+((GPIO_0+GPIO_1+GPIO_2+GPIO_5)<<2)) 
		mov	r0, #(GPIO_2+GPIO_5)
		str	r0,[r6]
		
	;--------------------------------------------------
	; Configuration GPIO Port H en sortie
	;--------------------------------------------------
		ldr	r6, =GPIODIR_H 
		mov	r0,	#0x03
		str	r0,[r6]
		
		ldr	r6, =GPIODR2R_H
		mov r0, #0x03	
		str	r0,[r6]
		
		ldr	r6, =GPIODEN_H
		mov r0, #0x03	
		str	r0,[r6]
		
	; Direction initiale
		ldr	r6, =(GPIODATA_H +(GPIO_1<<2))
		mov	r0, #0x02
		str	r0,[r6]		
		
		BX	LR

;--------------------------------------------------
; Contrôle moteur droit
;--------------------------------------------------
MOTEUR_DROIT_ON
		ldr	r6,	=PWMENABLE
		ldr r0, [r6]
		orr r0,	#0x01		; Activer sortie PWM0
		str	r0,	[r6]
		BX	LR

MOTEUR_DROIT_OFF 
		ldr	r6,	=PWMENABLE
		ldr r0,	[r6]
		and	r0,	#0x0E		; Désactiver sortie PWM0
		str	r0,	[r6]
		BX	LR

MOTEUR_DROIT_ARRIERE
		ldr	r6, =(GPIODATA_D+(GPIO_1<<2)) 
		mov	r0, #0		; Direction arrière
		str	r0,[r6]
		BX	LR

MOTEUR_DROIT_AVANT
		ldr	r6, =(GPIODATA_D+(GPIO_1<<2)) 
		mov	r0, #2		; Direction avant
		str	r0,[r6]
		BX	LR

MOTEUR_DROIT_INVERSE
		ldr	r6, =(GPIODATA_D+(GPIO_1<<2)) 
		ldr	r1, [r6]
		EOR	r0, r1, #GPIO_1	; Inverser direction
		str	r0,[r6]
		BX	LR

;--------------------------------------------------
; Contrôle moteur gauche
;--------------------------------------------------
MOTEUR_GAUCHE_ON
		ldr	r6,	=PWMENABLE
		ldr	r0, [r6]
		orr	r0,	#0x04		; Activer sortie PWM2
		str	r0,	[r6]
		BX	LR

MOTEUR_GAUCHE_OFF
		ldr	r6,	=PWMENABLE
		ldr	r0,	[r6]
		and	r0,	#0x0B		; Désactiver sortie PWM2
		str	r0,	[r6]
		BX	LR

MOTEUR_GAUCHE_ARRIERE
		ldr	r6, =(GPIODATA_H+(GPIO_1<<2)) 
		mov	r0, #2		; Direction arrière (inverse moteur droit)
		str	r0,[r6]
		BX	LR		

MOTEUR_GAUCHE_AVANT
		ldr	r6, =(GPIODATA_H+(GPIO_1<<2)) 
		mov	r0, #0		; Direction avant
		str	r0,[r6]
		BX	LR		

MOTEUR_GAUCHE_INVERSE
		ldr	r6, =(GPIODATA_H+(GPIO_1<<2)) 
		ldr	r1, [r6]
		EOR	r0, r1, #GPIO_1	; Inverser direction
		str	r0,[r6]
		BX	LR

		END