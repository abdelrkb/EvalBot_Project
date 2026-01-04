;; RK - Evalbot (Cortex M3 de Texas Instrument)
; Bibliothèque - Configuration et gestion des LEDs, Bumpers et Switches

;; Adresses de base des ports
GPIO_PORTD_BASE     EQU 0x40007000
GPIO_PORTE_BASE     EQU 0x40024000
GPIO_PORTF_BASE     EQU 0x40025000

;; Offsets des registres GPIO
GPIO_O_DIR          EQU 0x400
GPIO_O_DEN          EQU 0x51C
GPIO_O_DR2R         EQU 0x500
GPIO_O_PUR          EQU 0x510
GPIO_O_LOCK         EQU 0x520
GPIO_O_CR           EQU 0x524
GPIO_LOCK_KEY       EQU 0x4C4F434B

;; Registre horloge système
SYSCTL_RCGC2        EQU 0x400FE108

;; Masques des broches
; LEDs sur Port F
LED1                EQU 0x10    ; PF4
LED2                EQU 0x20    ; PF5
ALL_LEDS            EQU 0x30    ; PF4 + PF5

; Bumpers sur Port E
BUMPER_RIGHT        EQU 0x01    ; PE0
BUMPER_LEFT         EQU 0x02    ; PE1
ALL_BUMPERS         EQU 0x03    ; PE0 + PE1

; Switches sur Port D
SW1                 EQU 0x40    ; PD6
SW2                 EQU 0x80    ; PD7
ALL_SWITCHES        EQU 0xC0    ; PD6 + PD7

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
        ; Activer horloge Port D, Port E et Port F
        ldr r6, = SYSCTL_RCGC2
        ldr r0, [r6]
        orr r0, r0, #0x38   ; Bit 3 (Port D) + Bit 4 (Port E) + Bit 5 (Port F)
        str r0, [r6]
        nop
        nop
        nop
        
        ;--------------------------------------------------
        ; Configuration LEDs (Port F) en sortie
        ;--------------------------------------------------
        ; Direction: sortie
        ldr r6, = GPIO_PORTF_BASE + GPIO_O_DIR
        mov r0, #ALL_LEDS
        str r0, [r6]
        
        ; Digital Enable
        ldr r6, = GPIO_PORTF_BASE + GPIO_O_DEN
        mov r0, #ALL_LEDS
        str r0, [r6]
        
        ; 2mA Drive
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
        ; Digital Enable
        ldr r6, = GPIO_PORTE_BASE + GPIO_O_DEN
        mov r0, #ALL_BUMPERS
        str r0, [r6]
        
        ; Pull-Up resistor (bumpers à 1 par défaut, 0 quand appuyés)
        ldr r6, = GPIO_PORTE_BASE + GPIO_O_PUR
        mov r0, #ALL_BUMPERS
        str r0, [r6]
        
        ;--------------------------------------------------
        ; Configuration Switches SW1 et SW2 (Port D) en entrée
        ;--------------------------------------------------
        ; Déverrouiller Port D
        ldr r6, = GPIO_PORTD_BASE + GPIO_O_LOCK
        ldr r0, = GPIO_LOCK_KEY
        str r0, [r6]
        ldr r6, = GPIO_PORTD_BASE + GPIO_O_CR
        mov r0, #ALL_SWITCHES
        str r0, [r6]
        
        ; Digital Enable
        ldr r6, = GPIO_PORTD_BASE + GPIO_O_DEN
        ldr r0, [r6]
        orr r0, r0, #ALL_SWITCHES
        str r0, [r6]
        
        ; Pull-Up resistor
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
        ; Toggle les deux LEDs
        ldr r6, = GPIO_PORTF_BASE + (ALL_LEDS << 2)
        ldr r0, [r6]
        eor r0, r0, #ALL_LEDS
        str r0, [r6]
        BX LR

;--------------------------------------------------
; Fonctions Bumpers (retournent 0 si appuyé, 1 sinon)
;--------------------------------------------------
BUMPER_RIGHT_READ
        ldr r6, = GPIO_PORTE_BASE + (BUMPER_RIGHT << 2)
        ldr r0, [r6]
        tst r0, #BUMPER_RIGHT
        beq bumper_right_pressed
        mov r0, #1      ; Non appuyé
        BX LR
bumper_right_pressed
        mov r0, #0      ; Appuyé
        BX LR

BUMPER_LEFT_READ
        ldr r6, = GPIO_PORTE_BASE + (BUMPER_LEFT << 2)
        ldr r0, [r6]
        tst r0, #BUMPER_LEFT
        beq bumper_left_pressed
        mov r0, #1      ; Non appuyé
        BX LR
bumper_left_pressed
        mov r0, #0      ; Appuyé
        BX LR

;--------------------------------------------------
; Fonctions Switches (retournent 0 si appuyé, 1 sinon)
;--------------------------------------------------
SW1_READ
        ldr r6, = GPIO_PORTD_BASE + (SW1 << 2)
        ldr r0, [r6]
        tst r0, #SW1
        beq sw1_pressed
        mov r0, #1      ; Non appuyé
        BX LR
sw1_pressed
        mov r0, #0      ; Appuyé
        BX LR

SW2_READ
        ldr r6, = GPIO_PORTD_BASE + (SW2 << 2)
        ldr r0, [r6]
        tst r0, #SW2
        beq sw2_pressed
        mov r0, #1      ; Non appuyé
        BX LR
sw2_pressed
        mov r0, #0      ; Appuyé
        BX LR

        END