        AREA |.text|, CODE, READONLY

SYSCTL_RCGC2        EQU 0x400FE108

GPIO_PORTF_BASE     EQU 0x40025000
GPIO_PORTD_BASE     EQU 0x40007000

GPIO_O_DIR          EQU 0x400
GPIO_O_DEN          EQU 0x51C
GPIO_O_PUR          EQU 0x510
GPIO_O_DR2R         EQU 0x500
GPIO_O_LOCK         EQU 0x520
GPIO_O_CR           EQU 0x524

GPIO_LOCK_KEY       EQU 0x4C4F434B

; LED1
PIN4                EQU 0x10   ; PF4

; Switch SW1
SW1                 EQU 0x40   ; PD6 (actif bas)

; Variable toggle
LED_STATE           EQU 0x20000000   ; mémoire libre RAM


        ENTRY
        EXPORT __main

__main
        ;--------------------------------------------
        ; ACTIVER PORT F (LED) ET PORT D (SW1)
        ;--------------------------------------------
        ldr r6, = SYSCTL_RCGC2
        mov r0, #(0x20 + 0x08)   ; F + D
        str r0, [r6]
        nop
        nop
        nop

        ;--------------------------------------------
        ; DEVERROUILLER PD7 (nécessaire pour PTOUT)
        ;--------------------------------------------
        ldr r6, = GPIO_PORTD_BASE + GPIO_O_LOCK
        ldr r0, = GPIO_LOCK_KEY
        str r0, [r6]

        ldr r6, = GPIO_PORTD_BASE + GPIO_O_CR
        mov r0, #0x80       ; PD7
        str r0, [r6]


        ;--------------------------------------------
        ; CONFIG LED PF4 en sortie
        ;--------------------------------------------
        ldr r6, = GPIO_PORTF_BASE + GPIO_O_DIR
        mov r0, #PIN4
        str r0, [r6]

        ldr r6, = GPIO_PORTF_BASE + GPIO_O_DEN
        mov r0, #PIN4
        str r0, [r6]

        ldr r6, = GPIO_PORTF_BASE + GPIO_O_DR2R
        mov r0, #PIN4
        str r0, [r6]


        ;--------------------------------------------
        ; CONFIG SW1 (PD6) en entrée + pull-up
        ;--------------------------------------------
        ldr r6, = GPIO_PORTD_BASE + GPIO_O_DEN
        mov r0, #SW1
        str r0, [r6]

        ldr r6, = GPIO_PORTD_BASE + GPIO_O_PUR
        mov r0, #SW1
        str r0, [r6]


        ;--------------------------------------------
        ; Initialisation LED éteinte
        ;--------------------------------------------
        mov r0, #0
        ldr r6, = LED_STATE
        str r0, [r6]

        ldr r5, = GPIO_PORTF_BASE + (PIN4 << 2)   ; adresse DATA PF4
        ldr r7, = GPIO_PORTD_BASE + (SW1 << 2)    ; adresse DATA PD6


main_loop
        ; Lire SW1
        ldr r0, [r7]
        tst r0, #SW1
        bne main_loop        ; tant que le bouton n'est PAS appuyé (niveau 1)

        ;-------------------------
        ; Bouton appuyé ? Toggle
        ;-------------------------
        ldr r1, = LED_STATE
        ldr r2, [r1]
        eor r2, r2, #1       ; inverse 0?1
        str r2, [r1]

        ; Appliquer état LED
        cmp r2, #1
        beq led_on

led_off
        mov r3, #0
        str r3, [r5]
        b wait_release

led_on
        mov r3, #PIN4
        str r3, [r5]
        b wait_release


wait_release
        ; Attendre que le bouton soit relâché (anti-rebond)
rel_loop
        ldr r0, [r7]
        tst r0, #SW1
        beq rel_loop         ; tant que toujours appuyé

        ; retour boucle principale
        b main_loop

        END
