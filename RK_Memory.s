;; RK - Evalbot (Cortex M3 de Texas Instrument)
; Bibliothèque - Gestion mémoire des mouvements pour retour à la base

;; Zone mémoire RAM pour stocker les mouvements
MEMORY_BASE         EQU 0x20001000      ; Adresse de base en RAM
MAX_MOVES           EQU 100             ; Nombre max de mouvements stockés

;; Types de mouvements
MOVE_FORWARD        EQU 1               ; Avancer
MOVE_PIVOT_LEFT     EQU 2               ; Pivoter gauche (45°)
MOVE_PIVOT_RIGHT    EQU 3               ; Pivoter droite (45°)

;; Structure d'un mouvement en mémoire (2 mots de 32 bits = 8 octets)
;; [Type (4 octets)] [Durée (4 octets)]

        AREA    |.text|, CODE, READONLY
        ENTRY
        
        ;; Fonctions exportées
        EXPORT  MEMORY_INIT
        EXPORT  MEMORY_PUSH_FORWARD
        EXPORT  MEMORY_PUSH_PIVOT_LEFT
        EXPORT  MEMORY_PUSH_PIVOT_RIGHT
        EXPORT  MEMORY_GET_COUNT
        EXPORT  MEMORY_IS_FULL
        EXPORT  MEMORY_CLEAR
        
        ;; Variables en mémoire
        EXPORT  move_count              ; Nombre de mouvements enregistrés

;--------------------------------------------------
; Variables globales
;--------------------------------------------------
        AREA    |.data|, DATA, READWRITE
move_count      DCD     0               ; Compteur de mouvements

;--------------------------------------------------
; Initialiser le système de mémoire
;--------------------------------------------------
        AREA    |.text|, CODE, READONLY

MEMORY_INIT
        push {r0, r1, lr}
        
        ; Réinitialiser le compteur
        ldr r0, =move_count
        mov r1, #0
        str r1, [r0]
        
        pop {r0, r1, pc}

;--------------------------------------------------
; Enregistrer un mouvement AVANCER
; Paramètre : r0 = durée (en unités de WAIT)
;--------------------------------------------------
MEMORY_PUSH_FORWARD
        push {r1, r2, r3, r4, lr}
        
        ; Sauvegarder la durée
        mov r4, r0
        
        ; Vérifier si mémoire pleine
        bl MEMORY_IS_FULL
        cmp r0, #1
        beq push_forward_full
        
        ; Calculer l'adresse de stockage
        ldr r1, =move_count
        ldr r2, [r1]                    ; r2 = index actuel
        
        ; Adresse = MEMORY_BASE + (index * 8)
        ldr r3, =MEMORY_BASE
        lsl r0, r2, #3                  ; index * 8
        add r3, r3, r0                  ; r3 = adresse de stockage
        
        ; Stocker le type de mouvement
        mov r0, #MOVE_FORWARD
        str r0, [r3]                    ; [adresse] = type
        
        ; Stocker la durée
        str r4, [r3, #4]                ; [adresse+4] = durée
        
        ; Incrémenter le compteur
        add r2, r2, #1
        str r2, [r1]
        
push_forward_full
        pop {r1, r2, r3, r4, pc}

;--------------------------------------------------
; Enregistrer un PIVOT GAUCHE (45°)
;--------------------------------------------------
MEMORY_PUSH_PIVOT_LEFT
        push {r0, r1, r2, r3, lr}
        
        ; Vérifier si mémoire pleine
        bl MEMORY_IS_FULL
        cmp r0, #1
        beq push_left_full
        
        ; Calculer l'adresse
        ldr r1, =move_count
        ldr r2, [r1]
        ldr r3, =MEMORY_BASE
        lsl r0, r2, #3
        add r3, r3, r0
        
        ; Stocker le type
        mov r0, #MOVE_PIVOT_LEFT
        str r0, [r3]
        
        ; Durée = 0 (pas utilisée pour les pivots)
        mov r0, #0
        str r0, [r3, #4]
        
        ; Incrémenter le compteur
        add r2, r2, #1
        str r2, [r1]
        
push_left_full
        pop {r0, r1, r2, r3, pc}

;--------------------------------------------------
; Enregistrer un PIVOT DROITE (45°)
;--------------------------------------------------
MEMORY_PUSH_PIVOT_RIGHT
        push {r0, r1, r2, r3, lr}
        
        ; Vérifier si mémoire pleine
        bl MEMORY_IS_FULL
        cmp r0, #1
        beq push_right_full
        
        ; Calculer l'adresse
        ldr r1, =move_count
        ldr r2, [r1]
        ldr r3, =MEMORY_BASE
        lsl r0, r2, #3
        add r3, r3, r0
        
        ; Stocker le type
        mov r0, #MOVE_PIVOT_RIGHT
        str r0, [r3]
        
        ; Durée = 0
        mov r0, #0
        str r0, [r3, #4]
        
        ; Incrémenter le compteur
        add r2, r2, #1
        str r2, [r1]
        
push_right_full
        pop {r0, r1, r2, r3, pc}

;--------------------------------------------------
; Obtenir le nombre de mouvements enregistrés
; Retour : r0 = nombre de mouvements
;--------------------------------------------------
MEMORY_GET_COUNT
        push {r1, lr}
        ldr r1, =move_count
        ldr r0, [r1]
        pop {r1, pc}

;--------------------------------------------------
; Vérifier si la mémoire est pleine
; Retour : r0 = 1 si pleine, 0 sinon
;--------------------------------------------------
MEMORY_IS_FULL
        push {r1, r2, lr}
        ldr r1, =move_count
        ldr r2, [r1]
        cmp r2, #MAX_MOVES
        bge memory_full
        mov r0, #0                      ; Pas pleine
        b memory_check_end
memory_full
        mov r0, #1                      ; Pleine
memory_check_end
        pop {r1, r2, pc}

;--------------------------------------------------
; Effacer tous les mouvements
;--------------------------------------------------
MEMORY_CLEAR
        push {r0, r1, lr}
        ldr r0, =move_count
        mov r1, #0
        str r1, [r0]
        pop {r0, r1, pc}

        END