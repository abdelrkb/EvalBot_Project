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

RECUL_DURATION      EQU 1475           ; Durée du recul (15 clignotements)

__main
        ;--------------------------------------------------
        ; Initialisation complète du système
        ;--------------------------------------------------
        BL  MOTEUR_INIT                ; Init PWM et moteurs
        BL  IO_INIT                    ; Init LEDs, bumpers, switches
        BL  MEMORY_INIT                ; Init mémoire trajectoire
        
        BL  MOTEUR_DROIT_AVANT         ; Configurer direction avant
        BL  MOTEUR_GAUCHE_AVANT
        BL  ALL_LEDS_OFF               ; Éteindre les LEDs

;--------------------------------------------------
; Attente SW1 pour démarrer exploration
;--------------------------------------------------
wait_start
        BL  SW1_READ                   ; Lire état du switch 1
        cmp r0, #0
        bne wait_start                 ; Boucler tant que non pressé
        
        ; Anti-rebond
        BL  WAIT_SHORT
wait_release_sw1
        BL  SW1_READ
        cmp r0, #0
        beq wait_release_sw1           ; Attendre relâchement
        
        ; Préparer nouvelle exploration
        BL  MEMORY_CLEAR               ; Effacer ancienne trajectoire
        BL  MOTEUR_DROIT_AVANT         ; Forcer direction avant
        BL  MOTEUR_GAUCHE_AVANT
        BL  LED1_ON                    ; Signaler mode exploration

;==================================================
; MODE EXPLORATION
;==================================================
exploration_mode
        BL  MOTEUR_DROIT_ON            ; Activer les moteurs
        BL  MOTEUR_GAUCHE_ON
        mov r8, #0                     ; r8 = compteur de distance

check_during_exploration
        add r8, r8, #1                 ; Incrémenter distance parcourue
        
        ; Vérifier retour immédiat (SW2)
        BL  SW2_READ
        cmp r0, #0
        beq check_sw2_pressed          ; Si pressé, retour base
        
        ; Vérifier obstacle droit
        BL  BUMPER_RIGHT_READ
        cmp r0, #0
        beq obstacle_right_explore     ; Si pressé, traiter obstacle
        
        ; Vérifier obstacle gauche
        BL  BUMPER_LEFT_READ
        cmp r0, #0
        beq obstacle_left_explore
        
        ; Vérifier saturation mémoire
        BL  MEMORY_IS_FULL
        cmp r0, #1
        beq memory_full_alert          ; Si pleine, forcer retour
        
        BL  WAIT_STEP                  ; Petit délai entre itérations
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
        ; Arrêt immédiat
        BL  MOTEUR_DROIT_OFF
        BL  MOTEUR_GAUCHE_OFF
        BL  WAIT_SHORT
        
        ; Recul avec signal visuel
        BL  MOTEUR_DROIT_ARRIERE
        BL  MOTEUR_GAUCHE_ARRIERE
        BL  MOTEUR_DROIT_ON
        BL  MOTEUR_GAUCHE_ON
        BL  RECUL_AVEC_LEDS            ; 15 clignotements
        
        BL  MOTEUR_DROIT_OFF
        BL  MOTEUR_GAUCHE_OFF
        BL  WAIT_SHORT
        
        ; Corriger la distance nette
        ldr r0, =RECUL_DURATION
        subs r8, r8, r0                ; Distance nette = avance - recul
        bpl save_forward_right         ; Si positif, ok
        mov r8, #0                     ; Si négatif, clamp à 0
        
save_forward_right
        ; Enregistrer le mouvement
        mov r0, r8
        BL  MEMORY_PUSH_FORWARD
        mov r8, #0                     ; Reset compteur
        
        ; Pivoter à GAUCHE (opposé de l'obstacle)
        BL  MOTEUR_GAUCHE_ARRIERE
        BL  MOTEUR_DROIT_AVANT
        BL  MOTEUR_GAUCHE_ON
        BL  MOTEUR_DROIT_ON
        BL  WAIT_PIVOT
        
        BL  MOTEUR_DROIT_OFF
        BL  MOTEUR_GAUCHE_OFF
        BL  MEMORY_PUSH_PIVOT_LEFT     ; Enregistrer le pivot
        
        ; Reprendre exploration
        BL  MOTEUR_DROIT_AVANT
        BL  MOTEUR_GAUCHE_AVANT
        BL  LED1_ON
        b   exploration_mode

;--------------------------------------------------
; Obstacle GAUCHE détecté en exploration
;--------------------------------------------------
obstacle_left_explore
        ; Arrêt immédiat
        BL  MOTEUR_DROIT_OFF
        BL  MOTEUR_GAUCHE_OFF
        BL  WAIT_SHORT
        
        ; Recul avec signal visuel
        BL  MOTEUR_DROIT_ARRIERE
        BL  MOTEUR_GAUCHE_ARRIERE
        BL  MOTEUR_DROIT_ON
        BL  MOTEUR_GAUCHE_ON
        BL  RECUL_AVEC_LEDS
        
        BL  MOTEUR_DROIT_OFF
        BL  MOTEUR_GAUCHE_OFF
        BL  WAIT_SHORT
        
        ; Corriger la distance nette
        ldr r0, =RECUL_DURATION
        subs r8, r8, r0
        bpl save_forward_left
        mov r8, #0
        
save_forward_left
        mov r0, r8
        BL  MEMORY_PUSH_FORWARD
        mov r8, #0
        
        ; Pivoter à DROITE (opposé de l'obstacle)
        BL  MOTEUR_DROIT_ARRIERE
        BL  MOTEUR_GAUCHE_AVANT
        BL  MOTEUR_DROIT_ON
        BL  MOTEUR_GAUCHE_ON
        BL  WAIT_PIVOT
        
        BL  MOTEUR_DROIT_OFF
        BL  MOTEUR_GAUCHE_OFF
        BL  MEMORY_PUSH_PIVOT_RIGHT
        
        ; Reprendre exploration
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
        
        ; Alerte visuelle : 5 clignotements
        mov r4, #5
alert_blink
        BL  ALL_LEDS_ON
        BL  WAIT_BLINK
        BL  ALL_LEDS_OFF
        BL  WAIT_BLINK
        subs r4, r4, #1
        bne alert_blink
        
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
        
        ; Arrêt et passage en mode retour
        BL  MOTEUR_DROIT_OFF
        BL  MOTEUR_GAUCHE_OFF
        BL  ALL_LEDS_OFF
        BL  WAIT_SHORT
        BL  LED2_ON                    ; Signaler mode retour
        
        ; Préparer la lecture de trajectoire
        BL  MEMORY_GET_COUNT
        mov r9, r0                     ; r9 = nombre de mouvements
        
        cmp r9, #0
        beq arrived_at_base            ; Aucun mouvement, déjà à la base

;--------------------------------------------------
; Boucle de retour (rejouer à l'envers)
;--------------------------------------------------
return_loop
        subs r9, r9, #1                ; Décrémenter index
        blt arrived_at_base            ; Si < 0, terminé
        
        ; Calculer adresse du mouvement : base + (index * 8)
        ldr r10, =MEMORY_BASE
        lsl r0, r9, #3                 ; Offset = index * 8
        add r10, r10, r0
        
        ; Lire le mouvement
        ldr r0, [r10]                  ; r0 = type
        ldr r1, [r10, #4]              ; r1 = durée
        
        ; Dispatcher selon le type
        cmp r0, #MOVE_FORWARD
        beq return_forward
        cmp r0, #MOVE_PIVOT_LEFT
        beq return_pivot_left
        cmp r0, #MOVE_PIVOT_RIGHT
        beq return_pivot_right
        
        b return_loop                  ; Type inconnu, continuer

;--------------------------------------------------
; Retour : Inverser AVANCER = RECULER
;--------------------------------------------------
return_forward
        BL  MOTEUR_DROIT_ARRIERE
        BL  MOTEUR_GAUCHE_ARRIERE
        BL  MOTEUR_DROIT_ON
        BL  MOTEUR_GAUCHE_ON
        
        ; Reculer pendant la durée enregistrée
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
        BL  MOTEUR_DROIT_ARRIERE       ; Pivoter à droite
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
        BL  MOTEUR_GAUCHE_ARRIERE      ; Pivoter à gauche
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
        
        ; Célébration : 10 clignotements
        mov r4, #10
celebration_blink
        BL  ALL_LEDS_ON
        BL  WAIT_BLINK
        BL  ALL_LEDS_OFF
        BL  WAIT_BLINK
        subs r4, r4, #1
        bne celebration_blink
        
        b   wait_start                 ; Nouvelle exploration

;==================================================
; FONCTIONS AUXILIAIRES
;==================================================

;--------------------------------------------------
; Recul avec signal visuel (15 clignotements)
;--------------------------------------------------
RECUL_AVEC_LEDS
        push {r4, lr}                  ; Sauvegarder r4 et LR
        mov r4, #15
blink_loop
        BL  ALL_LEDS_ON
        BL  WAIT_BLINK
        BL  ALL_LEDS_OFF
        BL  WAIT_BLINK
        subs r4, r4, #1
        bne blink_loop
        pop {r4, pc}                   ; Restaurer et retourner

;--------------------------------------------------
; Attente courte (anti-rebond, transitions)
;--------------------------------------------------
WAIT_SHORT
        push {r1, lr}
        ldr r1, =0x3FFFF
wait_short_loop
        subs r1, #1
        bne wait_short_loop
        pop {r1, pc}

;--------------------------------------------------
; Petit délai (pas de temps pour avancement)
;--------------------------------------------------
WAIT_STEP
        push {r1, lr}
        ldr r1, =0x1FFF
wait_step_loop
        subs r1, #1
        bne wait_step_loop
        pop {r1, pc}

;--------------------------------------------------
; Délai pour clignotement visible
;--------------------------------------------------
WAIT_BLINK
        push {r1, lr}
        ldr r1, =0x5FFFF
wait_blink_loop
        subs r1, #1
        bne wait_blink_loop
        pop {r1, pc}

;--------------------------------------------------
; Délai pour rotation (calibré empiriquement)
;--------------------------------------------------
WAIT_PIVOT
        push {r1, lr}
        ldr r1, =0xAFFFFF
wait_pivot_loop
        subs r1, #1
        bne wait_pivot_loop
        pop {r1, pc}

        END