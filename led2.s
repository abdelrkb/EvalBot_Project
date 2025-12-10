		AREA    |.text|, CODE, READONLY
 
SYSCTL_PERIPH_GPIOF EQU     0x400FE108      ; Clock gating
GPIO_PORTF_BASE     EQU     0x40025000      ; Base port F

GPIO_O_DIR          EQU     0x00000400      
GPIO_O_DR2R         EQU     0x00000500
GPIO_O_DEN          EQU     0x0000051C

PIN4                EQU     0x10            ; 00010000
PIN5                EQU     0x20            ; 00100000

DUREE               EQU     0x002FFFFF

        ENTRY
        EXPORT __main

__main

        ;--------------------------------------------
        ; ENABLE CLOCK GPIOF
        ;--------------------------------------------
        ldr r6, = SYSCTL_PERIPH_GPIOF
        mov r0, #0x20               ; bit 5 = Port F
        str r0, [r6]

        ; delay obligatoire (3 cycles mini)
        nop
        nop
        nop

        ;--------------------------------------------
        ; CONFIGURATION DES LEDS (PIN4 + PIN5)
        ;--------------------------------------------
        ; DIR = sorties
        ldr r6, = GPIO_PORTF_BASE + GPIO_O_DIR
        mov r0, #(PIN4 + PIN5)
        str r0, [r6]

        ; DEN = digital enable
        ldr r6, = GPIO_PORTF_BASE + GPIO_O_DEN
        mov r0, #(PIN4 + PIN5)
        str r0, [r6]

        ; DR2R = drive 2mA
        ldr r6, = GPIO_PORTF_BASE + GPIO_O_DR2R
        mov r0, #(PIN4 + PIN5)
        str r0, [r6]

        ;--------------------------------------------
        ; ADRESSES GPIODATA (address masking)
        ;--------------------------------------------
        mov r2, #0x00          ; valeur pour éteindre
        mov r3, #PIN4          ; valeur pour allumer PIN4
        mov r4, #PIN5          ; valeur pour allumer PIN5

        ldr r5, = GPIO_PORTF_BASE + (PIN4 << 2)   ; adresse DATA PIN4
        ldr r6, = GPIO_PORTF_BASE + (PIN5 << 2)   ; adresse DATA PIN5

loop
        ; éteindre LEDs
        str r2, [r5]
        str r2, [r6]

        ; délai
        ldr r1, = DUREE
wait1   subs r1, #1
        bne wait1

        ; allumer LEDs
        str r3, [r5]
        str r4, [r6]

        ; délai
        ldr r1, = DUREE
wait2   subs r1, #1
        bne wait2

        b loop

        END