;; RK - Evalbot (Cortex M3 de Texas Instrument)
; Bibliothèque - Gestion mémoire des mouvements pour retour à la base

;; Zone mémoire RAM pour stocker les mouvements
MEMORY_BASE         EQU 0x20001000      ; Adresse de base en RAM
MAX_MOVES           EQU 100             ; Nombre max de mouvements stockés

;; Types de mouvements
MOVE_FORWARD        EQU 1               ; Avancer
MOVE_PIVOT_LEFT     EQU 2               ; Pivoter gauche
MOVE_PIVOT_RIGHT    EQU 3               ; Pivoter droite

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
        push {r0, r1, lr}               ; Sauvegarder les registres
        
        ldr r0, =move_count             ; Charger l'adresse du compteur
        mov r1, #0                      ; Initialiser à 0
        str r1, [r0]                    ; Écrire en mémoire
        
        pop {r0, r1, pc}                ; Restaurer et retourner

;--------------------------------------------------
; Enregistrer un mouvement AVANCER
; Paramètre : r0 = durée (en unités de WAIT)
;--------------------------------------------------
MEMORY_PUSH_FORWARD
        push {r1, r2, r3, r4, lr}
        
        mov r4, r0                      ; Sauvegarder la durée dans r4
        
        ; Vérifier si la mémoire est pleine
        bl MEMORY_IS_FULL
        cmp r0, #1
        beq push_forward_full           ; Si pleine, ne rien faire
        
        ; Calculer l'adresse où stocker le mouvement
        ldr r1, =move_count
        ldr r2, [r1]                    ; r2 = index actuel
        
        ldr r3, =MEMORY_BASE            ; r3 = adresse de base
        lsl r0, r2, #3                  ; r0 = index * 8 (chaque mouvement = 8 octets)
        add r3, r3, r0                  ; r3 = adresse finale
        
        ; Stocker le type
        mov r0, #MOVE_FORWARD
        str r0, [r3]                    ; Écrire le type à l'adresse
        
        ; Stocker la durée
        str r4, [r3, #4]                ; Écrire la durée 4 octets après
        
        ; Incrémenter le compteur
        add r2, r2, #1
        str r2, [r1]
        
push_forward_full
        pop {r1, r2, r3, r4, pc}

;--------------------------------------------------
; Enregistrer un PIVOT GAUCHE
;--------------------------------------------------
MEMORY_PUSH_PIVOT_LEFT
        push {r0, r1, r2, r3, lr}
        
        ; Vérifier si la mémoire est pleine
        bl MEMORY_IS_FULL
        cmp r0, #1
        beq push_left_full
        
        ; Calculer l'adresse
        ldr r1, =move_count
        ldr r2, [r1]                    ; Index actuel
        ldr r3, =MEMORY_BASE
        lsl r0, r2, #3                  ; Offset = index * 8
        add r3, r3, r0
        
        ; Stocker le type
        mov r0, #MOVE_PIVOT_LEFT
        str r0, [r3]
        
        ; Pas de durée pour les pivots
        mov r0, #0
        str r0, [r3, #4]
        
        ; Incrémenter le compteur
        add r2, r2, #1
        str r2, [r1]
        
push_left_full
        pop {r0, r1, r2, r3, pc}

;--------------------------------------------------
; Enregistrer un PIVOT DROITE
;--------------------------------------------------
MEMORY_PUSH_PIVOT_RIGHT
        push {r0, r1, r2, r3, lr}
        
        ; Vérifier si la mémoire est pleine
        bl MEMORY_IS_FULL
        cmp r0, #1
        beq push_right_full
        
        ; Calculer l'adresse
        ldr r1, =move_count
        ldr r2, [r1]                    ; Index actuel
        ldr r3, =MEMORY_BASE
        lsl r0, r2, #3                  ; Offset = index * 8
        add r3, r3, r0
        
        ; Stocker le type
        mov r0, #MOVE_PIVOT_RIGHT
        str r0, [r3]
        
        ; Pas de durée pour les pivots
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
        ldr r1, =move_count             ; Charger l'adresse du compteur
        ldr r0, [r1]                    ; Lire la valeur
        pop {r1, pc}                    ; Retourner avec r0 = count

;--------------------------------------------------
; Vérifier si la mémoire est pleine
; Retour : r0 = 1 si pleine, 0 sinon
;--------------------------------------------------
MEMORY_IS_FULL
        push {r1, r2, lr}
        ldr r1, =move_count
        ldr r2, [r1]                    ; Lire le nombre actuel
        cmp r2, #MAX_MOVES              ; Comparer avec le max
        bge memory_full                 ; Si >= 100, c'est plein
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
        ldr r0, =move_count             ; Charger l'adresse
        mov r1, #0                      ; Mettre à 0
        str r1, [r0]                    ; Réinitialiser le compteur
        pop {r0, r1, pc}

        END