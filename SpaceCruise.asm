;*****************************************************************************
;  Author: Jonathan Jones
;  Date: 05/10/2026
;  Revision: 1.0
;
;  Description: An outerspace flying game in-which the player manuevers a ship
;                    to avoid meteors.
;     
;  Notes: The program runs best with the display screen at a width of 30 characters.
;
;  Register Usage:
;     R0 - 
;     R1 - 
;     R2 - 
;     R3 - 
;     R4 - Not used
;     R5 - Not used
;     R6 - 
;     R7 - Not used

;****************************************************************************/
.ORIG   x3000
        LD R6, STACK    ;store stack pointer in R6
        JSR initGame    ;prepare game operation
        
    gameLoop
        JSR inputCheck          ;check for input (keys: A, D)
        JSR updateAsteroids     ;move asteroids
        JSR collisionCheck      ;check for asteroid-ship collision (R0!=0 means collision)
        ADD R0, R0, #0          ;set condition based on R0
        BRp collided            ;R0 != 0 means collision
        JSR drawGame            ;render screen
        ;TODO: increase speed
        
        ; JSR delay               ;creates game-pace
        LD R1, SPEED        ;hardcoded to #10000
    delayLoop           ;countdown to create delay
        ADD R1, R1, #-1
        BRzp delayLoop
        
        LD R0, SCORE
        ADD R0, R0, #1      ;R0=1
        ST R0, SCORE        ;increment score
    BR gameLoop         ;repeat until collision

collided
    JSR gameOver        ;show game over message and score

HALT

STACK       .FILL   x4015
;************************initGame*****************************
;  Description: Initialize player position, score,
;               and asteroids array.
;
;R0 - 
;R1 - 
;R2 - 
;R3 - 
;R4 - Not used
;R5 - Not used
;R6 - Used as a stack pointer
;R7 - Not used
;**************************************************************
initGame
    ;Store registers in stack
    ADD R6, R6, #-1
    STR R2, R6, #0
    ADD R6, R6, #-1
    STR R3, R6, #0
    ADD R6, R6, #-1
    STR R4, R6, #0
    ADD R6, R6, #-1
    STR R5, R6, #0
    ADD R6, R6, #-1
    STR R7, R6, #0
    
    LEA R0, WELCOME_MSG
    PUTS
    LEA R0, NEW_LINE
    PUTS

    beginLoop               ;wait for user to enter any key
        LDI R4, KBSR        ;keyboard ready check
        BRzp beginLoop
    LDI R0, KBDR        ;consume input
    
    
    ;player start position
    LD R0, SCREEN_WIDTH
    ADD R0, R0, #-7
    ST R0, PLAYER_POS
    
    ;reset score
    AND R0, R0, #0
    ST R0, SCORE
    
    ;clear asteroids
    LEA R1, ASTEROIDS       ;asteroids array
    LD R2, MAX_ASTEROIDS    ;counter for asteroids
    LD R3, NEG_ONE
initClearLoop
        STR R3, R1, #0      ;start at row=-1
        STR R3, R1, #1
        ADD R1, R1, #2      ;add asteroid
        ADD R2, R2, #-1     ;decrement asteroid counter
    BRp initClearLoop
    
    ;Restore registers from stack
    LDR R7, R6, #0
    ADD R6, R6, #1
    LDR R5, R6, #0
    ADD R6, R6, #1
    LDR R4, R6, #0
    ADD R6, R6, #1
    LDR R3, R6, #0
    ADD R6, R6, #1
    LDR R2, R6, #0
    ADD R6, R6, #1

RET

WELCOME_MSG     .STRINGZ    "|-SPACE CRUISE-|\nPress any key to begin..."
;************************inputCheck*****************************
;  Description: Check keyboard for left or right movement,
;               exclusively using 'a' (left) or 'd' (right)
;       
;R0 - 
;R1 - 
;R2 - 
;R3 - 
;R4 - Not used
;R5 - Not used
;R6 - Used as stack pointer
;R7 - Not used
;**************************************************************
inputCheck
    ;Store registers in stack
    ADD R6, R6, #-1
    STR R7, R6, #0
    ADD R6, R6, #-1
    STR R3, R6, #0
    ADD R6, R6, #-1
    STR R2, R6, #0
    ADD R6, R6, #-1
    STR R1, R6, #0

    LDI R1, KBSR        ;keyboard ready check
    BRzp noInput
    LDI R0, KBDR        ;store keyboard data in R0
    
    LD R1, NEG_ASCII_a  
    ADD R1, R0, R1      ;subtract to check
    BRz moveLeft        ;'a' entered
    
    LD R1, NEG_ASCII_d
    ADD R1, R0, R1      ;subtract to check
    BRz moveRight       ;'d' entered
    BR noInput
    
    moveLeft
        LD R0, PLAYER_POS   ;current position
        ADD R0, R0, #-1     ;decrement current
        BRn noInput         ;prevents move off left edge
        ST R0, PLAYER_POS   ;save new position
        BR noInput          ;move complete
    
    moveRight
        LD R0, PLAYER_POS       ;test right move for boundary violation
        ADD R0, R0, #1          ;tentative new position
        LD R1, SCREEN_WIDTH
        NOT R1, R1              ;make negative screen width
        ADD R1, R1, #1
        ADD R0, R0, R1          ;compare to width - 1
        BRzp noInput             ;move would be out of bounds
        ;right move ok
        LD R0, PLAYER_POS       ;reload ship position
        ADD R0, R0, #1          ;increment right 1 column
        ST R0, PLAYER_POS       ;save new position

    noInput     ;finish polling              
    LDI R0, KBDR        ;consume input
    ;Restore registers from stack
    LDR R1, R6, #0
    ADD R6, R6, #1
    LDR R2, R6, #0
    ADD R6, R6, #1
    LDR R3, R6, #0
    ADD R6, R6, #1
    LDR R7, R6, #0
    ADD R6, R6, #1
RET

;=========================Data Section==============================;
SCREEN_WIDTH    .FILL   #16         ;screen: 16w x 8h
SCREEN_HEIGHT   .FILL   #10
PLAYER_ROW      .FILL   #9         ;spaceship always at bottom (row 18)
PLAYER_POS      .BLKW   1
ASCII_SHIP      .FILL   #65         ;'A'
ASCII_ASTEROID  .FILL   #42         ;'*'
ASCII_SPACE     .FILL   #32         ;' '
MAX_ASTEROIDS   .FILL   #8          ;no more than 8 asteroids at a time
ASTEROIDS       .BLKW   16          ;8 asteroids * 2 words (row & col) each
SCORE           .BLKW   1
SPEED           .FILL   #13000      ;preset speed
; SPEED           .BLKW   1         ;use for variable speed
SEED            .FILL   xACE1       ;random number generator seed
MAGIC_SEED      .Fill   #17         ;prime number for randomness
NEW_LINE        .STRINGZ    "\n"
NEG_ASCII_a     .FILL       #-97
NEG_ASCII_d     .FILL       #-100
NEG_ONE         .FILL       #-1
KBSR            .FILL       xFE00
KBDR            .FILL       xFE02
DSR             .FILL       xFE04
DDR             .FILL       xFE06
NEWLINE         .FILL       #10
TEN             .FILL       #10
;===================================================================;

;************************getRandom***********************************
;  Description: Random number generator using linear feedback shift
;       
;   Note: Psuedorandom number (0-29) returned in R0. 
;           Seed updates each call.
;R0 - Used for random number output
;R1 - Used for maximum value (usually SCREEN_WIDTH)
;R2 - used 
;R3 - used 
;R4 - Used for magical seed salt
;R5 - Not used
;R6 - Used as stack pointer
;R7 - 
;********************************************************************
getRandom
    ;save registers
    ADD R6, R6, #-1
    STR R2, R6, #0
    ADD R6, R6, #-1
    STR R3, R6, #0
    ADD R6, R6, #-1
    STR R4, R6, #0      
    ADD R6, R6, #-1
    STR R7, R6, #0
    
    LD R0, SEED
    LD R4, MAGIC_SEED
    
    ;seed = (seed * 5) + 17 (quasi randomness)
    ADD R2, R0, R0      ;R2 = seed*2
    ADD R2, R2, R2      ;R2 = seed*4
    ADD R2, R2, R0      ;R2 = seed*5
    ADD R2, R2, R4      ;R2 + 17
    ST R2, SEED         ;save new seed
    ADD R0, R2, #0      ;save in R0
    
    ;modulo for R1 passed by caller
modLoop
    ADD R2, R1, #0      ;copy R1 (modulus) into R2
    NOT R3, R2
    ADD R3, R3, #1      ;R3 = -R2 for subtraction
    ADD R3, R0, R3      
    BRn modDone         ;modulo gathered if negative
    ADD R0, R3, #0      ;else R0=R0-R2
    BR modLoop          ;keep modulating
    
modDone
    ;Restore registers
    LDR R7, R6, #0
    ADD R6, R6, #1
    LDR R4, R6, #0
    ADD R6, R6, #1
    LDR R3, R6, #0
    ADD R6, R6, #1
    LDR R2, R6, #0
    ADD R6, R6, #1
RET
    

;************************updateAsteroids*****************************
;  Description: Move all active asteroids down. Recycle bottom
;               row asteroids to top row (with random position)
;  Note: Spawns one new asteroid if any asteroid slots are empty.
;R0 - 
;R1 - Points to asteroids array 
;R2 - stores MAX_ASTEROIDS as counter
;R3 - used for asteroid row
;R4 - stores SCREEN_WIDTH, SCREEN_HEIGHT for validation checks
;R5 - Not used
;R6 - Used as stack pointer
;R7 - 
;********************************************************************
updateAsteroids
    ;Store registers in stack
    ADD R6, R6, #-1
    STR R1, R6, #0
    ADD R6, R6, #-1
    STR R2, R6, #0
    ADD R6, R6, #-1
    STR R3, R6, #0
    ADD R6, R6, #-1
    STR R4, R6, #0
    ADD R6, R6, #-1
    STR R5, R6, #0
    ADD R6, R6, #-1
    STR R7, R6, #0
    
    LEA R1, ASTEROIDS       ;asteroids array
    LD R2, MAX_ASTEROIDS    ;counter for asteroids

    ;move asteroids down, spawn new ones, despawn old ones
    ;loop through asteroids
astLoop
    LDR R3, R1, #0      ;asteroid row
    ADD R4, R3, #1      ;if row was -1, it is now 0 and inactive
    BRz nextAsteroid    ;this one's inactive
    
    ADD R3, R3, #1      ;move asteroid down
    STR R3, R1, #0      ;save change
    
    ;check for row >= SCREEN_HEIGHT
    LD R4, SCREEN_HEIGHT
    NOT R4, R4          ;make negative
    ADD R4, R4, #1
    ADD R4, R3, R4      ;row minus height
    BRn stillOnScreen
    
    ;at bottom triggers respawn at top
    AND R3, R3, #0
    STR R3, R1, #0      ;row = 0
    
    ADD R6, R6, #-1     ;temporarily save asteroid
    STR R1, R6, #0      ;   in stack
    LD R1, SCREEN_WIDTH ;send R1 to get random
    JSR getRandom       ;random position (0-29)
    
    LDR R1, R6, #0      ;restore asteroid pointer
    ADD R6, R6, #1      ;increment stack
    STR R0, R1, #1      ;store new column
    
stillOnScreen
nextAsteroid
    ADD R1, R1, #2      ;next asteroid (each is 2 words)
    ADD R2, R2, #-1     ;decrement asteroid count
    BRp astLoop

    LEA R1, ASTEROIDS   ;reload R1
    LD R2, MAX_ASTEROIDS
findEmpty
    LDR R3, R1, #0      ;load current asteroid's row for checking in R3
    ADD R3, R3, #1      ;next row
    BRz foundEmpty      ;was -1, now zero == empty row
    
    ADD R1, R1, #2      ;next asteroid (each is 2 words)
    ADD R2, R2, #-1     ;decrement asteroid count
    BRp findEmpty
    BR noSpawn
foundEmpty
    AND R3, R3, #0      ;clear R3
    STR R3, R1, #0      ;row 0
    
    ADD R6, R6, #-1     ;temp save asteroid
    STR R1, R6, #0
    
    LD R1, SCREEN_WIDTH ;load modulus for randomness
    JSR getRandom       ;random position (0-29
    
    LDR R1, R6, #0      ;restore asteroid pointer
    ADD R6, R6, #1
    
    STR R0, R1, #1      ;store column

noSpawn
    ;Restore registers from stack
    LDR R7, R6, #0
    ADD R6, R6, #1
    LDR R5, R6, #0
    ADD R6, R6, #1
    LDR R4, R6, #0
    ADD R6, R6, #1
    LDR R3, R6, #0
    ADD R6, R6, #1
    LDR R2, R6, #0
    ADD R6, R6, #1
    LDR R1, R6, #0
    ADD R6, R6, #1
RET

;************************drawGame************************************
;  Description: Redraw screen each frame. 
;               Player '^'', asteroids '*'', and space ' '
;       
;R0 - 
;R1 - Used 
;R2 - used 
;R3 - used 
;R4 - Not used
;R5 - Not used
;R6 - Used as stack pointer
;R7 - 
;********************************************************************
drawGame
    ;clear console
    ; LD R1, #5
    ; clearLoop
    ;     LD R0, NEWLINE
    ;     OUT
    ;     ADD R1, R1, #-1
    ;     BRp clearLoop
    ;save registers
    ADD R6, R6, #-6
    STR R1, R6, #0
    STR R2, R6, #1
    STR R3, R6, #2
    STR R4, R6, #3
    STR R5, R6, #4
    STR R7, R6, #5
    
    LD R3, SCREEN_HEIGHT    ;row counter
    AND R4, R4, #0          ;clear R4 for current row number
    
    ; LEA R0, BORDER_TOP
    ; PUTS
    
    ;loop over rows 0-19
rowLoop
    LD R5, SCREEN_WIDTH     ;column counter
    AND R2, R2, #0          ;current column=0

    ;loop over column 0-29
colLoop
    ;if (row,col) == player: print '^'
    LD R0, PLAYER_ROW       ;bottom row
    NOT R0, R0
    ADD R0, R0, #1          ;-PLAYER_ROW
    ADD R0, R0, R4          ;same row = 0 = player
    BRnp notPlayer
    LD R0, PLAYER_POS
    NOT R0, R0
    ADD R0, R0, #1          ;-PLAYER_POS
    ADD R0, R0, R2          ;same column = 0 = player
    BRnp notPlayer
    LD R0, ASCII_SHIP       ;set ship '^'
    BR printChar
    
    ;else if (row,col) == asteroid: print *
notPlayer
    ;check asteroids
    LEA R1, ASTEROIDS
    LD R7, MAX_ASTEROIDS
checkAst
    LDR R0, R1, #0      ;Asteroid row
    NOT R0, R0
    ADD R0, R0, #1      ;-asteroid row
    ADD R0, R0, R4      ;zero = asteroid row match
    BRnp nextAst
    LDR R0, R1, #1      ;asteroid column
    NOT R0, R0
    ADD R0, R0, #1      ;-asteroid column
    ADD R0, R0, R2      ;zero = asteroid column match
    BRnp nextAst
    LD R0, ASCII_ASTEROID   ;'*'
    BR printChar

nextAst
    ADD R1, R1, #2      ;move to next asteroid (2 words each)
    ADD R7, R7, #-1     ;decrement asteroid count
    BRp checkAst
    
    LD R0, ASCII_SPACE  ;' '

printChar    ;else print ' '
    OUT
    ADD R2, R2, #1      ;move to next column
    ADD R5, R5, #-1     ;decrement column counter
    BRp colLoop
    
    ;move to newline 
    LD R0, NEWLINE
    OUT
    ADD R4, R4, #1      ;move to next row
    ADD R3, R3, #-1     ;decrement row counter
    BRp rowLoop
    
    ;Restore registers
    LDR R7, R6, #5
    LDR R5, R6, #4
    LDR R4, R6, #3
    LDR R3, R6, #2
    LDR R2, R6, #1
    LDR R1, R6, #0
    ADD R6, R6, #6
RET
; Draw variables
BORDER_TOP  .STRINGZ    "=============================="

;************************collisionCheck*****************************
;  Description: Checks for player-asteroid sharing same space
;
;   Notes: Returns R0=1 for collission, and R0=0 otherwise.
;       
;R0 - Returns collission/not collision status
;R1 - Used 
;R2 - used 
;R3 - used 
;R4 - Not used
;R5 - Not used
;R6 - Used as stack pointer
;R7 - 
;********************************************************************
collisionCheck
    ;save registers
    ADD R6, R6, #-1
    STR R1, R6, #0
    ADD R6, R6, #-1
    STR R2, R6, #0
    ADD R6, R6, #-1
    STR R3, R6, #0
    ADD R6, R6, #-1
    STR R4, R6, #0
    ADD R6, R6, #-1
    STR R7, R6, #0
    
    LEA R1, ASTEROIDS           ;pointer to asteroid array
    LD R2, MAX_ASTEROIDS        ;loop counter
    
    AND R0, R0, #0              ;clear R0
    
    ;check active asteroids
checkLoop
    LDR R3, R1, #0          ;R3=asteroid row
    ADD R4, R3, #1          ;increment row
    BRz nextAstCollision    ;row==-1 then inactive asteroid
    
    ;if (row,col) == (PLAYER_ROW, PLAYER_POS) then collision
    LD R4, PLAYER_ROW
    NOT R4, R4
    ADD R4, R4, #1          ;make negative
    ADD R4, R3, R4          ;subtract rows for comparison
    BRnp nextAstCollision       ;not same row
    
    ;same row, check column
    LDR R3, R1, #1          ;R3=asteroid column
    LD R4, PLAYER_POS
    NOT R4, R4
    ADD R4, R4, #1          ;negative player column
    ADD R4, R3, R4          ;subtract to check
    BRnp nextAstCollision       ;no collision
    
    ;collision
    ADD R0, R0, #1          ;return 1 for collision
    BR collisionDone
    
nextAstCollision
    ADD R1, R1, #2          ;asteroids are 2 words each
    ADD R2, R2, #-1         ;decrement counter
    BRp checkLoop
    
    ;no collision
    AND R0, R0, #0          ;return 0 for no collision

collisionDone
    
    ;restore registers
    LDR R7, R6, #0
    ADD R6, R6, #1
    LDR R4, R6, #0
    ADD R6, R6, #1
    LDR R3, R6, #0
    ADD R6, R6, #1
    LDR R2, R6, #0
    ADD R6, R6, #1
    LDR R1, R6, #0
    ADD R6, R6, #1
RET

;************************delay***************************************
;  Description: Controls game speed using simply busy delay
;       
;R0 - used to store speed
;R1 - Used 
;R2 - used 
;R3 - used 
;R4 - Not used
;R5 - Not used
;R6 - Used as stack pointer
;R7 - 
;********************************************************************
delay

    ; LD R0, SPEED        ;hardcoded to #8000
    ; delayLoop1           ;countdown to create delay
    ;     ADD R0, R0, #-1
    ;     BRzp delayLoop1
        
    ; LD R0, SPEED        ;hardcoded to #8000
    ; delayLoop2           ;countdown to create delay
    ;     ADD R0, R0, #-1
    ;     BRp delayLoop2
    ; LD R0, SPEED        ;hardcoded to #8000
    ; delayLoop3          ;countdown to create delay
    ;     ADD R0, R0, #-1
    ;     BRp delayLoop3
    ; LD R0, SPEED        ;hardcoded to #8000
    ; delayLoop4          ;countdown to create delay
    ;     ADD R0, R0, #-1
    ;     BRp delayLoop4
    ; LD R0, SPEED        ;hardcoded to #8000
    ; delayLoop5          ;countdown to create delay
    ;     ADD R0, R0, #-1
    ;     BRp delayLoop5
    ; LD R0, SPEED        ;hardcoded to #8000
    ; delayLoop6          ;countdown to create delay
    ;     ADD R0, R0, #-1
    ;     BRp delayLoop6
    ; LD R0, SPEED        ;hardcoded to #8000
    ; delayLoop7          ;countdown to create delay
    ;     ADD R0, R0, #-1
    ;     BRp delayLoop7
    ; LD R0, SPEED        ;hardcoded to #8000
    ; delayLoop8          ;countdown to create delay
    ;     ADD R0, R0, #-1
    ;     BRp delayLoop8
    ; LD R0, SPEED        ;hardcoded to #8000
    ; delayLoop9          ;countdown to create delay
    ;     ADD R0, R0, #-1
    ;     BRp delayLoop9
RET

;************************gameOver***********************************
;  Description: Displays game over screen and final score.
;       
;R0 - Used for printing output
;R1 - Used 
;R2 - used 
;R3 - used 
;R4 - Not used
;R5 - Not used
;R6 - Used as stack pointer
;R7 - 
;********************************************************************
gameOver
    LEA R0, GAME_OVER_MSG
    PUTS
    ; LEA R0, SCORE_MSG
    ; PUTS
    ; LD R0, SCORE
    ; PUTS
RET

GAME_OVER_MSG   .STRINGZ    "\n\n\n\n\n\n\n\n\n\n***********GAME OVER!***********\n\n"
SCORE_MSG       .STRINGZ    "FINAL SCORE: "

.END