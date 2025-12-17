;; Programme principal - Contrôle moteurs Evalbot avec bouton SW1
;; Appuyer sur SW1 pour démarrer/arrêter les moteurs
		AREA    |.text|, CODE, READONLY
		ENTRY
		EXPORT	__main
		
		;; Import des fonctions moteurs
		IMPORT	MOTEUR_INIT
		IMPORT	MOTEUR_DROIT_ON
		IMPORT  MOTEUR_DROIT_OFF
		IMPORT  MOTEUR_DROIT_AVANT
		IMPORT	MOTEUR_GAUCHE_ON
		IMPORT  MOTEUR_GAUCHE_OFF
		IMPORT  MOTEUR_GAUCHE_AVANT

;; Registres GPIO pour le bouton SW1
SYSCTL_RCGC2        EQU 0x400FE108
GPIO_PORTD_BASE     EQU 0x40007000
GPIO_O_DIR          EQU 0x400
GPIO_O_DEN          EQU 0x51C
GPIO_O_PUR          EQU 0x510
GPIO_O_LOCK         EQU 0x520
GPIO_O_CR           EQU 0x524
GPIO_LOCK_KEY       EQU 0x4C4F434B

;; Bouton SW1 sur PD6
SW1                 EQU 0x40

;; Variable d'état moteur en RAM
MOTOR_STATE         EQU 0x20000100

__main	
		;--------------------------------------------------
		; Configuration du bouton SW1 (PD6)
		;--------------------------------------------------
		; Activer clock Port D (déjà fait dans MOTEUR_INIT mais on s'assure)
		ldr r6, = SYSCTL_RCGC2
		ldr r0, [r6]
		orr r0, r0, #0x08   ; Port D
		str r0, [r6]
		nop
		nop
		nop
		
		; Déverrouiller PD7 (sécurité)
		ldr r6, = GPIO_PORTD_BASE + GPIO_O_LOCK
		ldr r0, = GPIO_LOCK_KEY
		str r0, [r6]
		ldr r6, = GPIO_PORTD_BASE + GPIO_O_CR
		mov r0, #0x80
		str r0, [r6]
		
		; Configurer SW1 (PD6) en entrée avec pull-up
		ldr r6, = GPIO_PORTD_BASE + GPIO_O_DEN
		mov r0, #SW1
		str r0, [r6]
		ldr r6, = GPIO_PORTD_BASE + GPIO_O_PUR
		mov r0, #SW1
		str r0, [r6]
		
		;--------------------------------------------------
		; Initialiser les moteurs
		;--------------------------------------------------
		BL	MOTEUR_INIT
		
		; Configurer moteurs en mode AVANT (mais pas encore allumés)
		BL	MOTEUR_DROIT_AVANT
		BL	MOTEUR_GAUCHE_AVANT
		
		; Initialiser l'état moteur à 0 (arrêtés)
		mov r0, #0
		ldr r1, = MOTOR_STATE
		str r0, [r1]
		
		; Adresse du bouton SW1
		ldr r7, = GPIO_PORTD_BASE + (SW1 << 2)

;--------------------------------------------------
; Boucle principale
;--------------------------------------------------
main_loop
		; Lire l'état du bouton SW1
		ldr r0, [r7]
		tst r0, #SW1
		bne main_loop        ; Si bouton non appuyé, continuer d'attendre
		
		; Bouton appuyé ! Toggle l'état des moteurs
		ldr r1, = MOTOR_STATE
		ldr r2, [r1]
		eor r2, r2, #1       ; Inverser l'état (0?1 ou 1?0)
		str r2, [r1]
		
		; Vérifier l'état et allumer/éteindre les moteurs
		cmp r2, #1
		beq start_motors
		
stop_motors
		BL	MOTEUR_DROIT_OFF
		BL	MOTEUR_GAUCHE_OFF
		b	wait_release
		
start_motors
		BL	MOTEUR_DROIT_ON
		BL	MOTEUR_GAUCHE_ON
		b	wait_release

;--------------------------------------------------
; Attendre le relâchement du bouton (anti-rebond)
;--------------------------------------------------
wait_release
		ldr r0, [r7]
		tst r0, #SW1
		beq wait_release     ; Tant que bouton enfoncé
		
		; Petit délai anti-rebond supplémentaire
		mov r3, #0xFFFF
debounce_delay
		subs r3, #1
		bne debounce_delay
		
		b main_loop

		END