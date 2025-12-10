        AREA |.text|, CODE, READONLY

SYSCTL_RCGC2        EQU 0x400FE108

GPIO_PORTF_BASE     EQU 0x40025000
GPIO_PORTE_BASE     EQU 0x40024000

GPIO_O_DIR          EQU 0x400
GPIO_O_DEN          EQU 0x51C
GPIO_O_PUR          EQU 0x510
GPIO_O_DR2R         EQU 0x500

; LEDs (sortie)
PIN4                EQU 0x10   ; PF4 LED1
PIN5                EQU 0x20   ; PF5 LED2

; Bumpers (entrée)
E0                  EQU 0x01   ; PE0 Bumper Right
E1                  EQU 0x02   ; PE1 Bumper Left

        ENTRY
        EXPORT __main

__main
        ;--------------------------------------------
        ; ACTIVER CLOCK POUR PORT F ET PORT E
        ;--------------------------------------------
        ldr r6, = SYSCTL_RCGC2
        mov r0, #(0x20 + 0x10)       ; bit5=F, bit4=E
        str r0, [r6]
        nop
        nop
        nop

        ;--------------------------------------------
        ; CONFIG LEDs PF4 PF5
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
        ; CONFIG bumpers PE0 PE1
        ;--------------------------------------------
        ldr r6, = GPIO_PORTE_BASE + GPIO_O_DEN
        mov r0, #(E0 + E1)
        str r0, [r6]

        ; Activer pull-up (car bumpers reliés à GND)
        ldr r6, = GPIO_PORTE_BASE + GPIO_O_PUR
        mov r0, #(E0 + E1)
        str r0, [r6]

        ;--------------------------------------------
        ; Adresses DATA
        ;--------------------------------------------
        ldr r5, = GPIO_PORTF_BASE + (PIN4 << 2)   ; LED PF4
        ldr r6, = GPIO_PORTF_BASE + (PIN5 << 2)   ; LED PF5

        ldr r7, = GPIO_PORTE_BASE + (E0 << 2)     ; Bumper PE0
        ldr r8, = GPIO_PORTE_BASE + (E1 << 2)     ; Bumper PE1

loop
        ; LED PF4 gérée par PE0
        ldr r0, [r7]
        tst r0, #E0
        beq led4_off
        mov r1, #PIN4
        str r1, [r5]
        b check_led5

led4_off
        mov r1, #0
        str r1, [r5]

check_led5
        ; LED PF5 gérée par PE1
        ldr r0, [r8]
        tst r0, #E1
        beq led5_off
        mov r1, #PIN5
        str r1, [r6]
        b loop

led5_off
        mov r1, #0
        str r1, [r6]
        b loop

        END
