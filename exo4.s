        AREA |.text|, CODE, READONLY

SYSCTL_RCGC2        EQU 0x400FE108

GPIO_PORTF_BASE     EQU 0x40025000
GPIO_PORTD_BASE     EQU 0x40007000   ; Port D APB

GPIO_O_DIR          EQU 0x400
GPIO_O_DEN          EQU 0x51C
GPIO_O_PUR          EQU 0x510
GPIO_O_DR2R         EQU 0x500
GPIO_O_LOCK         EQU 0x520
GPIO_O_CR           EQU 0x524

GPIO_LOCK_KEY       EQU 0x4C4F434B

; LEDs (PF4 et PF5)
PIN4                EQU 0x10
PIN5                EQU 0x20

; Switchs (PD6 et PD7)
SW1                 EQU 0x40
SW2                 EQU 0x80

        ENTRY
        EXPORT __main

__main
        ;--------------------------------------------
        ; ACTIVER CLOCK pour PORT F et PORT D
        ;--------------------------------------------
        ldr r6, = SYSCTL_RCGC2
        mov r0, #(0x20 + 0x08)      ; F(bit5) + D(bit3)
        str r0, [r6]
        nop
        nop
        nop

        ;--------------------------------------------
        ; DEVERROUILLER PD7
        ;--------------------------------------------
        ldr r6, = GPIO_PORTD_BASE + GPIO_O_LOCK
        ldr r0, = GPIO_LOCK_KEY
        str r0, [r6]

        ldr r6, = GPIO_PORTD_BASE + GPIO_O_CR
        mov r0, #SW2               ; autoriser PD7
        str r0, [r6]

        ;--------------------------------------------
        ; CONFIG LEDs PF4 PF5 en sortie
        ;--------------------------------------------
        ldr r6, = GPIO_PORTF_BASE + GPIO_O_DIR
        mov r0, #(PIN4 + PIN5)
        str r0, [r6]

        ldr r6, = GPIO_PORTF_BASE + GPIO_O_DEN
        mov r0, #(PIN4 + PIN5)
        str r0, [r6]

        ldr r6, = GPIO_PORTF_BASE + GPIO_O_DR2R
        mov r0, #(PIN4 + PIN5)
        str r0, [r6]

        ;--------------------------------------------
        ; CONFIG SW1 et SW2 en entrée
        ;--------------------------------------------
        ldr r6, = GPIO_PORTD_BASE + GPIO_O_DEN
        mov r0, #(SW1 + SW2)
        str r0, [r6]

        ; Pull-up sur PD6 et PD7
        ldr r6, = GPIO_PORTD_BASE + GPIO_O_PUR
        mov r0, #(SW1 + SW2)
        str r0, [r6]

        ;--------------------------------------------
        ; Adresses DATA (LEDs et SWITCH)
        ;--------------------------------------------
        ldr r5, = GPIO_PORTF_BASE + (PIN4 << 2)   ; LED1
        ldr r6, = GPIO_PORTF_BASE + (PIN5 << 2)   ; LED2

        ldr r7, = GPIO_PORTD_BASE + (SW1 << 2)    ; SW1
        ldr r8, = GPIO_PORTD_BASE + (SW2 << 2)    ; SW2

loop
        ;--- SW1 appuyé ? => allumer LED1 ---
        ldr r0, [r7]
        tst r0, #SW1
        beq led1_on

        ; sinon LED1 OFF
        mov r1, #0
        str r1, [r5]
        b check_led2

led1_on
        mov r1, #PIN4
        str r1, [r5]

check_led2
        ;--- SW2 appuyé ? => allumer LED2 ---
        ldr r0, [r8]
        tst r0, #SW2
        beq led2_on

        mov r1, #0
        str r1, [r6]
        b loop

led2_on
        mov r1, #PIN5
        str r1, [r6]
        b loop

        END
