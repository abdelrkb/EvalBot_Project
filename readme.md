EVALGUST 3000
Robot Aspirateur Autonome avec Navigation par Mémorisation
À propos du Projet
Groupe : Binôme numéro 3
Membres : Zeroual Ilyes, Abdelnour Rekkab
Classe : E3FI-3L-s1
EVALGUST 3000 est un robot aspirateur autonome développé sur plateforme Evalbot (Texas Instruments LM3S9B92). Le robot explore une zone en évitant les obstacles et retrouve automatiquement son point de départ en rejouant sa trajectoire à l'envers. Le projet est entièrement codé en assembleur ARM.
Concept
Le robot fonctionne sans GPS ni encodeurs. Il mémorise simplement ses mouvements pendant l'exploration, puis les inverse pour revenir au départ :

Avancer 10 secondes → Reculer 10 secondes
Pivoter gauche → Pivoter droite
Pivoter droite → Pivoter gauche

C'est comme dérouler un fil d'Ariane, puis le suivre en sens inverse.
Fonctionnalités
Exploration

Avancement automatique avec détection d'obstacles
Évitement par pivot de 45° (gauche si obstacle à droite, droite si obstacle à gauche)
Mémorisation de tous les mouvements (jusqu'à 100)
Compensation automatique de la distance de recul après collision

Retour à la Base

Déclenchement manuel par bouton (SW2)
Déclenchement automatique si mémoire pleine
Inversion complète de la trajectoire
Rejeu des mouvements du dernier au premier

Indicateurs LED

LED1 : Mode exploration en cours
LED2 : Mode retour en cours
Clignotements : Recul après obstacle ou fin de mission

Architecture du Code
Le projet est divisé en 4 fichiers assembleur :
RK_Config_Moteurs.s

Configuration PWM des deux moteurs
Fonctions de base : avancer, reculer, tourner, arrêter
Contrôle de vitesse

RK_Config_IO.s

Gestion des LEDs d'indication
Lecture des capteurs bumpers
Lecture des boutons SW1 et SW2

RK_Memory.s

Système de mémorisation en RAM (0x20001000)
Enregistrement des mouvements avec leur durée
Capacité : 100 mouvements

RK_PrisenMain_Moteurs.s

Programme principal
Logique d'exploration
Algorithme de retour
Coordination de tous les modules

Matériel

Plateforme : Evalbot (Texas Instruments)
Microcontrôleur : LM3S9B92 (Cortex-M3)
Capteurs : 2 bumpers (collision)
Actionneurs : 2 moteurs DC avec PWM
Interface : 2 LEDs, 2 boutons

Utilisation

Compilation

Ouvrir le projet dans Keil µVision
Compiler les 4 fichiers assembleur


Déploiement

Connecter l'Evalbot via USB
Flasher le programme


Fonctionnement

Allumer le robot
Appuyer sur SW1 pour démarrer l'exploration
Le robot explore et évite les obstacles (LED1 allumée)
Appuyer sur SW2 pour retourner à la base (ou attendre mémoire pleine)
Le robot revient au point de départ (LED2 allumée)
10 clignotements = mission accomplie



Paramètres Ajustables
assemblyVITESSE         EQU  0x1A2      ; Vitesse des moteurs
RECUL_DURATION  EQU  1475       ; Compensation du recul
WAIT_PIVOT      EQU  0xAFFFFF   ; Durée d'un pivot 45°
```

Ces valeurs peuvent être modifiées pour calibrer le comportement selon la surface et l'état de la batterie.

## Algorithme de Navigation
```
Exploration :
1. Avancer en comptant le temps
2. Si obstacle détecté :
    - Reculer
    - Enregistrer distance nette (avancée - recul)
    - Pivoter 45° dans la direction opposée
    - Enregistrer le pivot
3. Répéter jusqu'à SW2 ou mémoire pleine

Retour :
1. Lire les mouvements en sens inverse
2. Pour chaque mouvement :
    - AVANCER → RECULER
    - PIVOT_LEFT → PIVOT_RIGHT
    - PIVOT_RIGHT → PIVOT_LEFT
3. Arrivée au départ
```

## Exemple de Trajectoire

**Aller :**
```
1. Avance 2000 unités
2. Tape un mur → Recule → Distance nette : 525 unités
3. Pivote gauche
4. Avance 1500 unités
5. SW2 appuyé
```

**Retour :**
```
1. Recule 1500 unités
2. Pivote droite
3. Recule 525 unités
   → Retour au point de départ
   Limitations

Précision ±10-20 cm (pas d'encodeurs absolus)
Maximum 100 mouvements mémorisables
Performance variable selon friction et batterie
Optimal sur surface plane

Outils de Développement

IDE : Keil µVision
Langage : Assembleur ARM (ARMv7-M)
Débogueur : Stellaris ICDI
Documentation : Datasheet LM3S9B92


Projet réalisé dans le cadre du module Systèmes Embarqués - E3FI-3L-s1