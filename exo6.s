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

; LEDs
PIN4                EQU 0x10    ; PF4 LED1
PIN5                EQU 0x20    ; PF5 LED2
ALL_LEDS            EQU 0x30    ; PF4 + PF5

; bouton SW1
SW1                 EQU 0x40    ; PD6

; variable toggle
STATE               EQU 0x20000000


        ENTRY
        EXPORT __main

__main
        ;--------------------------------------------------
        ; ACTIVER CLOCK PORT F et PORT D
        ;--------------------------------------------------
        ldr r6, = SYSCTL_RCGC2
        mov r0, #(0x20 + 0x08)   ; F(bit5) + D(bit3)
        str r0, [r6]
        nop
        nop
        nop

        ;--------------------------------------------------
        ; DEVERROUILLER PD7 (obligatoire)
        ;--------------------------------------------------
        ldr r6, = GPIO_PORTD_BASE + GPIO_O_LOCK
        ldr r0, = GPIO_LOCK_KEY
        str r0, [r6]

        ldr r6, = GPIO_PORTD_BASE + GPIO_O_CR
        mov r0, #0x80       ; PD7
        str r0, [r6]

        ;--------------------------------------------------
        ; CONFIG LEDs PF4 PF5 en sortie
        ;--------------------------------------------------
        ldr r6, = GPIO_PORTF_BASE + GPIO_O_DIR
        mov r0, #ALL_LEDS
        str r0, [r6]

        ldr r6, = GPIO_PORTF_BASE + GPIO_O_DEN
        mov r0, #ALL_LEDS
        str r0, [r6]

        ldr r6, = GPIO_PORTF_BASE + GPIO_O_DR2R
        mov r0, #ALL_LEDS
        str r0, [r6]

        ;--------------------------------------------------
        ; CONFIG SW1 (PD6) en entrée + pull-up
        ;--------------------------------------------------
        ldr r6, = GPIO_PORTD_BASE + GPIO_O_DEN
        mov r0, #SW1
        str r0, [r6]

        ldr r6, = GPIO_PORTD_BASE + GPIO_O_PUR
        mov r0, #SW1
        str r0, [r6]

        ;--------------------------------------------------
        ; Initialiser LEDs éteintes
        ;--------------------------------------------------
        mov r0, #0
        ldr r1, = STATE
        str r0, [r1]

        ; adresses DATA LEDs et bouton
        ldr r5, = GPIO_PORTF_BASE + (PIN4 << 2)
        ldr r6, = GPIO_PORTF_BASE + (PIN5 << 2)
        ldr r7, = GPIO_PORTD_BASE + (SW1  << 2)


main_loop
        ; Lire SW1
        ldr r0, [r7]
        tst r0, #SW1
        bne main_loop        ; tant que non appuyé


        ;------------------------------
        ; Toggle LEDs
        ;------------------------------
        ldr r1, = STATE
        ldr r2, [r1]
        eor r2, r2, #1        ; inverse état
        str r2, [r1]

        ; appliquer l'état aux LEDs PF4 & PF5
        cmp r2, #1
        beq leds_on

leds_off
        mov r3, #0
        str r3, [r5]
        str r3, [r6]
        b wait_release

leds_on
        mov r3, #PIN4
        str r3, [r5]
        mov r3, #PIN5
        str r3, [r6]
        b wait_release


wait_release
        ; attendre le relâchement du bouton (anti-rebond)
rel_loop
        ldr r0, [r7]
        tst r0, #SW1
        beq rel_loop
        b main_loop

        END
