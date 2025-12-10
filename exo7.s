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
PIN4                EQU 0x10     ; PF4 : LED1
PIN5                EQU 0x20     ; PF5 : LED2

; Switch
SW1                 EQU 0x40     ; PD6

; Variable d’état (0 ou 1)
STATE               EQU 0x20000000


        ENTRY
        EXPORT __main

__main
        ;--------------------------------------------------
        ; ACTIVER PORT F ET PORT D
        ;--------------------------------------------------
        ldr r6, = SYSCTL_RCGC2
        mov r0, #(0x20 + 0x08)     ; F(bit5) + D(bit3)
        str r0, [r6]
        nop
        nop
        nop

        ;--------------------------------------------------
        ; DEVERROUILLER PD7 (obligatoire pour le port D)
        ;--------------------------------------------------
        ldr r6, = GPIO_PORTD_BASE + GPIO_O_LOCK
        ldr r0, = GPIO_LOCK_KEY
        str r0, [r6]

        ldr r6, = GPIO_PORTD_BASE + GPIO_O_CR
        mov r0, #0x80            ; PD7
        str r0, [r6]


        ;--------------------------------------------------
        ; CONFIGURATION LEDs PF4 + PF5 en sortie
        ;--------------------------------------------------
        ldr r6, = GPIO_PORTF_BASE + GPIO_O_DIR
        mov r0, #(PIN4 + PIN5)
        str r0, [r6]

        ldr r6, = GPIO_PORTF_BASE + GPIO_O_DEN
        mov r0, #(PIN4 + PIN5)
        str r0, [r6]

        ldr r6, = GPIO_PORTF_BASE + GPIO_O_DR2R
        mov r0, #(PIN4 + PIN5)
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
        ; Initialisation de l'état (0 = LED1 OFF, LED2 ON)
        ;--------------------------------------------------
        mov r0, #0
        ldr r1, = STATE
        str r0, [r1]

        ; Adresses DATA
        ldr r5, = GPIO_PORTF_BASE + (PIN4 << 2)   ; LED1
        ldr r6, = GPIO_PORTF_BASE + (PIN5 << 2)   ; LED2
        ldr r7, = GPIO_PORTD_BASE + (SW1  << 2)   ; bouton SW1


main_loop
        ; Lire SW1 (actif bas)
        ldr r0, [r7]
        tst r0, #SW1
        bne main_loop           ; attendre appui


        ;--------------------------------------------------
        ;    INVERSION DES DEUX LEDs (TOGGLE ÉTATS)
        ;--------------------------------------------------
        ldr r1, = STATE
        ldr r2, [r1]
        eor r2, r2, #1          ; 0->1 ou 1->0
        str r2, [r1]

        ; Si état = 1 : LED1 ON, LED2 OFF
        cmp r2, #1
        beq etat1

etat0
        ; Etat = 0 ? LED1 OFF, LED2 ON
        mov r3, #0
        str r3, [r5]            ; PF4 = 0
        mov r3, #PIN5
        str r3, [r6]            ; PF5 = ON
        b wait_release

etat1
        ; Etat = 1 ? LED1 ON, LED2 OFF
        mov r3, #PIN4
        str r3, [r5]            ; PF4 = ON
        mov r3, #0
        str r3, [r6]            ; PF5 = OFF
        b wait_release


wait_release
        ; Anti-rebond : attendre que le bouton soit relâché
rel_loop
        ldr r0, [r7]
        tst r0, #SW1
        beq rel_loop            ; tant qu'appuyé

        b main_loop


        END
