;; RK - Evalbot (Cortex M3 de Texas Instrument)
; Programme principal - Exploration avec mémoire et retour à la base
; SW1 = Démarrer exploration | SW2 = Retour à la base
; LED1 = Mode exploration | LED2 = Mode retour

        AREA    |.text|, CODE, READONLY
        ENTRY
        EXPORT  __main
        
        ;; Import fonctions moteurs
        IMPORT  MOTEUR_INIT
        IMPORT  MOTEUR_DROIT_ON
        IMPORT  MOTEUR_DROIT_OFF
        IMPORT  MOTEUR_GAUCHE_ON
        IMPORT  MOTEUR_GAUCHE_OFF
        IMPORT  MOTEUR_DROIT_AVANT
        IMPORT  MOTEUR_DROIT_ARRIERE
        IMPORT  MOTEUR_GAUCHE_AVANT
        IMPORT  MOTEUR_GAUCHE_ARRIERE
        
        ;; Import fonctions I/O
        IMPORT  IO_INIT
        IMPORT  LED1_ON
        IMPORT  LED1_OFF
        IMPORT  LED2_ON
        IMPORT  LED2_OFF
        IMPORT  ALL_LEDS_ON
        IMPORT  ALL_LEDS_OFF
        IMPORT  BUMPER_RIGHT_READ
        IMPORT  BUMPER_LEFT_READ
        IMPORT  SW1_READ
        IMPORT  SW2_READ
        
        ;; Import fonctions mémoire
        IMPORT  MEMORY_INIT
        IMPORT  MEMORY_PUSH_FORWARD
        IMPORT  MEMORY_PUSH_PIVOT_LEFT
        IMPORT  MEMORY_PUSH_PIVOT_RIGHT
        IMPORT  MEMORY_GET_COUNT
        IMPORT  MEMORY_IS_FULL
        IMPORT  MEMORY_CLEAR

;; Constantes
MEMORY_BASE         EQU 0x20001000
MOVE_FORWARD        EQU 1
MOVE_PIVOT_LEFT     EQU 2
MOVE_PIVOT_RIGHT    EQU 3

;; Durée estimée du recul (à calibrer)
RECUL_DURATION      EQU 1475    ; Correspond à 15 clignotements

__main
        ;--------------------------------------------------
        ; Initialisation complète
        ;--------------------------------------------------
        BL  MOTEUR_INIT
        BL  IO_INIT
        BL  MEMORY_INIT
        
        BL  MOTEUR_DROIT_AVANT
        BL  MOTEUR_GAUCHE_AVANT
        BL  ALL_LEDS_OFF

;--------------------------------------------------
; Attente SW1 pour démarrer exploration
;--------------------------------------------------
wait_start
        BL  SW1_READ
        cmp r0, #0
        bne wait_start
        
        ; Anti-rebond
        BL  WAIT_SHORT
wait_release_sw1
        BL  SW1_READ
        cmp r0, #0
        beq wait_release_sw1
        
        ; Effacer l'ancienne mémoire
        BL  MEMORY_CLEAR
        
        ; LED1 ON = Mode exploration
        BL  LED1_ON

;==================================================
; MODE EXPLORATION
;==================================================
exploration_mode
        BL  MOTEUR_DROIT_ON
        BL  MOTEUR_GAUCHE_ON
        
        ; Compteur pour enregistrer le temps d'avancement
        mov r8, #0              ; r8 = compteur de temps

check_during_exploration
        ; Incrémenter le compteur de temps
        add r8, r8, #1
        
        ; Vérifier SW2 (retour immédiat)
        BL  SW2_READ
        cmp r0, #0
        beq check_sw2_pressed
        
        ; Vérifier bumper DROIT
        BL  BUMPER_RIGHT_READ
        cmp r0, #0
        beq obstacle_right_explore
        
        ; Vérifier bumper GAUCHE
        BL  BUMPER_LEFT_READ
        cmp r0, #0
        beq obstacle_left_explore
        
        ; Vérifier si mémoire pleine
        BL  MEMORY_IS_FULL
        cmp r0, #1
        beq memory_full_alert
        
        ; Continuer d'avancer
        BL  WAIT_STEP           ; Petit délai
        b   check_during_exploration

;--------------------------------------------------
; Branchement intermédiaire pour SW2
;--------------------------------------------------
check_sw2_pressed
        b   go_return_base

;--------------------------------------------------
; Obstacle DROIT détecté en exploration
;--------------------------------------------------
obstacle_right_explore
        ; Arrêt
        BL  MOTEUR_DROIT_OFF
        BL  MOTEUR_GAUCHE_OFF
        BL  WAIT_SHORT
        
        ; Recul avec LEDs
        BL  MOTEUR_DROIT_ARRIERE
        BL  MOTEUR_GAUCHE_ARRIERE
        BL  MOTEUR_DROIT_ON
        BL  MOTEUR_GAUCHE_ON
        BL  RECUL_AVEC_LEDS
        
        BL  MOTEUR_DROIT_OFF
        BL  MOTEUR_GAUCHE_OFF
        BL  WAIT_SHORT
        
        ; CORRECTION : Soustraire le temps de recul du compteur
        ; Distance nette = Distance avancée - Distance reculée
        ldr r0, =RECUL_DURATION
        subs r8, r8, r0         ; r8 = r8 - temps_recul
        bpl save_forward_right  ; Si positif, ok
        mov r8, #0              ; Si négatif, mettre à 0
        
save_forward_right
        ; Enregistrer le temps d'avancement NET
        mov r0, r8
        BL  MEMORY_PUSH_FORWARD
        mov r8, #0              ; Reset compteur
        
        ; Pivot GAUCHE
        BL  MOTEUR_GAUCHE_ARRIERE
        BL  MOTEUR_DROIT_AVANT
        BL  MOTEUR_GAUCHE_ON
        BL  MOTEUR_DROIT_ON
        BL  WAIT_PIVOT
        
        BL  MOTEUR_DROIT_OFF
        BL  MOTEUR_GAUCHE_OFF
        
        ; Enregistrer le pivot GAUCHE
        BL  MEMORY_PUSH_PIVOT_LEFT
        
        ; Remettre en mode AVANT
        BL  MOTEUR_DROIT_AVANT
        BL  MOTEUR_GAUCHE_AVANT
        BL  LED1_ON
        
        b   exploration_mode

;--------------------------------------------------
; Obstacle GAUCHE détecté en exploration
;--------------------------------------------------
obstacle_left_explore
        ; Arrêt
        BL  MOTEUR_DROIT_OFF
        BL  MOTEUR_GAUCHE_OFF
        BL  WAIT_SHORT
        
        ; Recul avec LEDs
        BL  MOTEUR_DROIT_ARRIERE
        BL  MOTEUR_GAUCHE_ARRIERE
        BL  MOTEUR_DROIT_ON
        BL  MOTEUR_GAUCHE_ON
        BL  RECUL_AVEC_LEDS
        
        BL  MOTEUR_DROIT_OFF
        BL  MOTEUR_GAUCHE_OFF
        BL  WAIT_SHORT
        
        ; CORRECTION : Soustraire le temps de recul
        ldr r0, =RECUL_DURATION
        subs r8, r8, r0
        bpl save_forward_left
        mov r8, #0
        
save_forward_left
        ; Enregistrer le temps d'avancement NET
        mov r0, r8
        BL  MEMORY_PUSH_FORWARD
        mov r8, #0
        
        ; Pivot DROITE
        BL  MOTEUR_DROIT_ARRIERE
        BL  MOTEUR_GAUCHE_AVANT
        BL  MOTEUR_DROIT_ON
        BL  MOTEUR_GAUCHE_ON
        BL  WAIT_PIVOT
        
        BL  MOTEUR_DROIT_OFF
        BL  MOTEUR_GAUCHE_OFF
        
        ; Enregistrer le pivot DROITE
        BL  MEMORY_PUSH_PIVOT_RIGHT
        
        ; Remettre en mode AVANT
        BL  MOTEUR_DROIT_AVANT
        BL  MOTEUR_GAUCHE_AVANT
        BL  LED1_ON
        
        b   exploration_mode

;--------------------------------------------------
; Mémoire pleine - Forcer retour
;--------------------------------------------------
memory_full_alert
        BL  MOTEUR_DROIT_OFF
        BL  MOTEUR_GAUCHE_OFF
        
        ; Clignoter 5 fois = alerte mémoire pleine
        mov r4, #5
alert_blink
        BL  ALL_LEDS_ON
        BL  WAIT_BLINK
        BL  ALL_LEDS_OFF
        BL  WAIT_BLINK
        subs r4, r4, #1
        bne alert_blink
        
        ; Forcer retour à la base
        b   go_return_base

;==================================================
; MODE RETOUR À LA BASE
;==================================================
go_return_base
        ; Enregistrer le dernier mouvement en cours
        cmp r8, #0
        beq skip_last_forward
        mov r0, r8
        BL  MEMORY_PUSH_FORWARD
skip_last_forward
        
        ; Arrêter les moteurs
        BL  MOTEUR_DROIT_OFF
        BL  MOTEUR_GAUCHE_OFF
        BL  ALL_LEDS_OFF
        BL  WAIT_SHORT
        
        ; LED2 ON = Mode retour
        BL  LED2_ON
        
        ; Obtenir le nombre de mouvements
        BL  MEMORY_GET_COUNT
        mov r9, r0              ; r9 = nombre total de mouvements
        
        ; Si aucun mouvement, on est déjà à la base
        cmp r9, #0
        beq arrived_at_base

;--------------------------------------------------
; Boucle de retour (rejouer à l'envers)
;--------------------------------------------------
return_loop
        subs r9, r9, #1         ; Décrémenter index (du dernier au premier)
        blt arrived_at_base     ; Si index < 0, terminé
        
        ; Calculer adresse du mouvement : MEMORY_BASE + (index * 8)
        ldr r10, =MEMORY_BASE
        lsl r0, r9, #3
        add r10, r10, r0        ; r10 = adresse du mouvement
        
        ; Lire type de mouvement
        ldr r0, [r10]           ; r0 = type
        ldr r1, [r10, #4]       ; r1 = durée
        
        ; Traiter selon le type
        cmp r0, #MOVE_FORWARD
        beq return_forward
        cmp r0, #MOVE_PIVOT_LEFT
        beq return_pivot_left
        cmp r0, #MOVE_PIVOT_RIGHT
        beq return_pivot_right
        
        b return_loop           ; Type inconnu, continuer

;--------------------------------------------------
; Retour : Inverser AVANCER = RECULER
;--------------------------------------------------
return_forward
        BL  MOTEUR_DROIT_ARRIERE
        BL  MOTEUR_GAUCHE_ARRIERE
        BL  MOTEUR_DROIT_ON
        BL  MOTEUR_GAUCHE_ON
        
        ; Avancer pendant la durée enregistrée
return_forward_wait
        subs r1, r1, #1
        ble return_forward_done
        BL  WAIT_STEP
        b   return_forward_wait
        
return_forward_done
        BL  MOTEUR_DROIT_OFF
        BL  MOTEUR_GAUCHE_OFF
        b   return_loop

;--------------------------------------------------
; Retour : Inverser PIVOT_LEFT = PIVOT_RIGHT
;--------------------------------------------------
return_pivot_left
        BL  MOTEUR_DROIT_ARRIERE
        BL  MOTEUR_GAUCHE_AVANT
        BL  MOTEUR_DROIT_ON
        BL  MOTEUR_GAUCHE_ON
        BL  WAIT_PIVOT
        BL  MOTEUR_DROIT_OFF
        BL  MOTEUR_GAUCHE_OFF
        BL  MOTEUR_DROIT_AVANT
        BL  MOTEUR_GAUCHE_AVANT
        b   return_loop

;--------------------------------------------------
; Retour : Inverser PIVOT_RIGHT = PIVOT_LEFT
;--------------------------------------------------
return_pivot_right
        BL  MOTEUR_GAUCHE_ARRIERE
        BL  MOTEUR_DROIT_AVANT
        BL  MOTEUR_GAUCHE_ON
        BL  MOTEUR_DROIT_ON
        BL  WAIT_PIVOT
        BL  MOTEUR_DROIT_OFF
        BL  MOTEUR_GAUCHE_OFF
        BL  MOTEUR_DROIT_AVANT
        BL  MOTEUR_GAUCHE_AVANT
        b   return_loop

;==================================================
; ARRIVÉE À LA BASE
;==================================================
arrived_at_base
        BL  MOTEUR_DROIT_OFF
        BL  MOTEUR_GAUCHE_OFF
        BL  ALL_LEDS_OFF
        
        ; Célébration : clignoter 10 fois
        mov r4, #10
celebration_blink
        BL  ALL_LEDS_ON
        BL  WAIT_BLINK
        BL  ALL_LEDS_OFF
        BL  WAIT_BLINK
        subs r4, r4, #1
        bne celebration_blink
        
        ; Retour au début
        b   wait_start

;==================================================
; FONCTIONS AUXILIAIRES
;==================================================
RECUL_AVEC_LEDS
        push {r4, lr}
        mov r4, #15
blink_loop
        BL  ALL_LEDS_ON
        BL  WAIT_BLINK
        BL  ALL_LEDS_OFF
        BL  WAIT_BLINK
        subs r4, r4, #1
        bne blink_loop
        pop {r4, pc}

WAIT_SHORT
        push {r1, lr}
        ldr r1, =0x3FFFF
wait_short_loop
        subs r1, #1
        bne wait_short_loop
        pop {r1, pc}

WAIT_STEP
        push {r1, lr}
        ldr r1, =0x1FFF         ; Petit pas de temps
wait_step_loop
        subs r1, #1
        bne wait_step_loop
        pop {r1, pc}

WAIT_BLINK
        push {r1, lr}
        ldr r1, =0x5FFFF
wait_blink_loop
        subs r1, #1
        bne wait_blink_loop
        pop {r1, pc}

WAIT_PIVOT
        push {r1, lr}
        ldr r1, =0xAFFFFF       ; Durée du pivot (à calibrer pour 45°)
wait_pivot_loop
        subs r1, #1
        bne wait_pivot_loop
        pop {r1, pc}

        END