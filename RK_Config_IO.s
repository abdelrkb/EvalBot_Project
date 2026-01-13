;; RK - Evalbot (Cortex M3 de Texas Instrument)
; Bibliothèque - Configuration et gestion des LEDs, Bumpers et Switches

;; Adresses de base des ports
GPIO_PORTD_BASE     EQU 0x40007000
GPIO_PORTE_BASE     EQU 0x40024000
GPIO_PORTF_BASE     EQU 0x40025000

;; Offsets des registres GPIO
GPIO_O_DIR          EQU 0x400          ; Direction (entrée/sortie)
GPIO_O_DEN          EQU 0x51C          ; Digital Enable
GPIO_O_DR2R         EQU 0x500          ; Drive 2mA
GPIO_O_PUR          EQU 0x510          ; Pull-Up Resistor
GPIO_O_LOCK         EQU 0x520          ; Verrouillage du port
GPIO_O_CR           EQU 0x524          ; Commit Register
GPIO_LOCK_KEY       EQU 0x4C4F434B     ; Clé de déverrouillage

;; Registre horloge système
SYSCTL_RCGC2        EQU 0x400FE108

;; Masques des broches
; LEDs sur Port F
LED1                EQU 0x10           ; PF4
LED2                EQU 0x20           ; PF5
ALL_LEDS            EQU 0x30           ; PF4 + PF5

; Bumpers sur Port E
BUMPER_RIGHT        EQU 0x01           ; PE0
BUMPER_LEFT         EQU 0x02           ; PE1
ALL_BUMPERS         EQU 0x03           ; PE0 + PE1

; Switches sur Port D
SW1                 EQU 0x40           ; PD6
SW2                 EQU 0x80           ; PD7
ALL_SWITCHES        EQU 0xC0           ; PD6 + PD7

        AREA    |.text|, CODE, READONLY
        ENTRY
        
        ;; Fonctions exportées
        EXPORT  IO_INIT
        EXPORT  LED1_ON
        EXPORT  LED1_OFF
        EXPORT  LED2_ON
        EXPORT  LED2_OFF
        EXPORT  ALL_LEDS_ON
        EXPORT  ALL_LEDS_OFF
        EXPORT  LED_TOGGLE
        EXPORT  BUMPER_RIGHT_READ
        EXPORT  BUMPER_LEFT_READ
        EXPORT  SW1_READ
        EXPORT  SW2_READ

;--------------------------------------------------
; Initialisation des LEDs, Bumpers et Switches
;--------------------------------------------------
IO_INIT
        ; Activer l'horloge pour les ports D, E et F
        ldr r6, = SYSCTL_RCGC2
        ldr r0, [r6]
        orr r0, r0, #0x38              ; Bit 3 (D) + Bit 4 (E) + Bit 5 (F)
        str r0, [r6]
        nop                            ; Attendre stabilisation horloge
        nop
        nop
        
        ;--------------------------------------------------
        ; Configuration LEDs (Port F) en sortie
        ;--------------------------------------------------
        ; Configurer comme sortie
        ldr r6, = GPIO_PORTF_BASE + GPIO_O_DIR
        mov r0, #ALL_LEDS
        str r0, [r6]
        
        ; Activer mode digital
        ldr r6, = GPIO_PORTF_BASE + GPIO_O_DEN
        mov r0, #ALL_LEDS
        str r0, [r6]
        
        ; Configurer courant 2mA
        ldr r6, = GPIO_PORTF_BASE + GPIO_O_DR2R
        mov r0, #ALL_LEDS
        str r0, [r6]
        
        ; Éteindre les LEDs au démarrage
        ldr r6, = GPIO_PORTF_BASE + (ALL_LEDS << 2)
        mov r0, #0
        str r0, [r6]
        
        ;--------------------------------------------------
        ; Configuration Bumpers (Port E) en entrée
        ;--------------------------------------------------
        ; Activer mode digital
        ldr r6, = GPIO_PORTE_BASE + GPIO_O_DEN
        mov r0, #ALL_BUMPERS
        str r0, [r6]
        
        ; Activer pull-up (bumpers à 1 par défaut, 0 si pressés)
        ldr r6, = GPIO_PORTE_BASE + GPIO_O_PUR
        mov r0, #ALL_BUMPERS
        str r0, [r6]
        
        ;--------------------------------------------------
        ; Configuration Switches (Port D) en entrée
        ;--------------------------------------------------
        ; Déverrouiller le Port D avec la clé
        ldr r6, = GPIO_PORTD_BASE + GPIO_O_LOCK
        ldr r0, = GPIO_LOCK_KEY
        str r0, [r6]
        
        ; Autoriser la modification des broches PD6 et PD7
        ldr r6, = GPIO_PORTD_BASE + GPIO_O_CR
        mov r0, #ALL_SWITCHES
        str r0, [r6]
        
        ; Activer mode digital
        ldr r6, = GPIO_PORTD_BASE + GPIO_O_DEN
        ldr r0, [r6]
        orr r0, r0, #ALL_SWITCHES
        str r0, [r6]
        
        ; Activer pull-up
        ldr r6, = GPIO_PORTD_BASE + GPIO_O_PUR
        ldr r0, [r6]
        orr r0, r0, #ALL_SWITCHES
        str r0, [r6]
        
        BX LR

;--------------------------------------------------
; Fonctions LEDs
;--------------------------------------------------
LED1_ON
        ldr r6, = GPIO_PORTF_BASE + (LED1 << 2)
        mov r0, #LED1
        str r0, [r6]
        BX LR

LED1_OFF
        ldr r6, = GPIO_PORTF_BASE + (LED1 << 2)
        mov r0, #0
        str r0, [r6]
        BX LR

LED2_ON
        ldr r6, = GPIO_PORTF_BASE + (LED2 << 2)
        mov r0, #LED2
        str r0, [r6]
        BX LR

LED2_OFF
        ldr r6, = GPIO_PORTF_BASE + (LED2 << 2)
        mov r0, #0
        str r0, [r6]
        BX LR

ALL_LEDS_ON
        ldr r6, = GPIO_PORTF_BASE + (ALL_LEDS << 2)
        mov r0, #ALL_LEDS
        str r0, [r6]
        BX LR

ALL_LEDS_OFF
        ldr r6, = GPIO_PORTF_BASE + (ALL_LEDS << 2)
        mov r0, #0
        str r0, [r6]
        BX LR

LED_TOGGLE
        ; Inverser l'état des deux LEDs
        ldr r6, = GPIO_PORTF_BASE + (ALL_LEDS << 2)
        ldr r0, [r6]                   ; Lire état actuel
        eor r0, r0, #ALL_LEDS          ; XOR pour inverser
        str r0, [r6]
        BX LR

;--------------------------------------------------
; Fonctions Bumpers
; Retournent : 0 si appuyé, 1 sinon
;--------------------------------------------------
BUMPER_RIGHT_READ
        ldr r6, = GPIO_PORTE_BASE + (BUMPER_RIGHT << 2)
        ldr r0, [r6]                   ; Lire état du bumper
        tst r0, #BUMPER_RIGHT          ; Tester le bit
        beq bumper_right_pressed       ; Si 0 ? appuyé
        mov r0, #1                     ; Non appuyé
        BX LR
bumper_right_pressed
        mov r0, #0                     ; Appuyé
        BX LR

BUMPER_LEFT_READ
        ldr r6, = GPIO_PORTE_BASE + (BUMPER_LEFT << 2)
        ldr r0, [r6]
        tst r0, #BUMPER_LEFT
        beq bumper_left_pressed
        mov r0, #1                     ; Non appuyé
        BX LR
bumper_left_pressed
        mov r0, #0                     ; Appuyé
        BX LR

;--------------------------------------------------
; Fonctions Switches
; Retournent : 0 si appuyé, 1 sinon
;--------------------------------------------------
SW1_READ
        ldr r6, = GPIO_PORTD_BASE + (SW1 << 2)
        ldr r0, [r6]                   ; Lire état du switch
        tst r0, #SW1                   ; Tester le bit
        beq sw1_pressed                ; Si 0 ? appuyé
        mov r0, #1                     ; Non appuyé
        BX LR
sw1_pressed
        mov r0, #0                     ; Appuyé
        BX LR

SW2_READ
        ldr r6, = GPIO_PORTD_BASE + (SW2 << 2)
        ldr r0, [r6]
        tst r0, #SW2
        beq sw2_pressed
        mov r0, #1                     ; Non appuyé
        BX LR
sw2_pressed
        mov r0, #0                     ; Appuyé
        BX LR

        END