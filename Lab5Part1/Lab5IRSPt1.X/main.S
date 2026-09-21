// Hunter Clezie
// RCET3375
// Lab4MuzakPt3
// https://github.com/hunterclezie-pixel/Lab-04---Funky-Muzak.git

; PIC16F883 Configuration Bit Settings

; Assembly source line config statements

; CONFIG1
  CONFIG  FOSC = XT             ; Oscillator Selection bits (XT oscillator: Crystal/resonator on RA6/OSC2/CLKOUT and RA7/OSC1/CLKIN)
  CONFIG  WDTE = OFF            ; Watchdog Timer Enable bit (WDT disabled and can be enabled by SWDTEN bit of the WDTCON register)
  CONFIG  PWRTE = OFF           ; Power-up Timer Enable bit (PWRT disabled)
  CONFIG  MCLRE = ON            ; RE3/MCLR pin function select bit (RE3/MCLR pin function is MCLR)
  CONFIG  CP = OFF              ; Code Protection bit (Program memory code protection is disabled)
  CONFIG  CPD = OFF             ; Data Code Protection bit (Data memory code protection is disabled)
  CONFIG  BOREN = OFF           ; Brown Out Reset Selection bits (BOR disabled)
  CONFIG  IESO = OFF            ; Internal External Switchover bit (Internal/External Switchover mode is disabled)
  CONFIG  FCMEN = OFF           ; Fail-Safe Clock Monitor Enabled bit (Fail-Safe Clock Monitor is disabled)
  CONFIG  LVP = OFF             ; Low Voltage Programming Enable bit (RB3 pin has digital I/O, HV on MCLR must be used for programming)

; CONFIG2
  CONFIG  BOR4V = BOR40V        ; Brown-out Reset Selection bit (Brown-out Reset set to 4.0V)
  CONFIG  WRT = OFF             ; Flash Program Memory Self Write Enable bits (Write protection off)

// config statements should precede project file includes.
#include <xc.inc>  
    ; General Purpose Registers
    keyLow      EQU 0x20    ; Stores note status bits 0-7
    keyHigh     EQU 0x21    ; Stores note status bits 8-15
    noteIndex   EQU 0x22    ; Stores selected note index
    outCount    EQU 0x23    ; Stores lookup table delay value
    inCount     EQU 0x24    ; Stores inner delay value
 
; Reset Vector at 0000h. Execution starts here after reset.
PSECT resetVect,class=CODE,delta=2
ResetVector:
    goto Setup

; Main code section starts at 0008h. User code goes here.
PSECT code,class=CODE,delta=2
 
Setup:
    BCF 0x03,6	; Sets Bank 0
    BCF 0x03,5	; Sets Bank 0
    CLRF 0x05	; Setting PORTA on reset to LOW
    CLRF 0x06	; Setting PORTB on reset to LOW
    CLRF 0x0A	; Clearing PCLATH for the lookup table

    BCF 0x03,6	; Sets Bank 1
    BSF 0x03,5	; Sets Bank 1
    CLRF 0x85	; Setting TRISA on reset to LOW, making PORTA an output
    BCF 0x81,7	; Making PORTB have weak pull-ups
    MOVLW 0xF0	; RB7-RB4 inputs, RB3-RB0 outputs
    MOVWF 0x86	; Setting TRISB for keypad inputs and outputs

        
    BSF 0x03,6	; Sets Bank 3    
    BSF 0x03,5	; Sets Bank 3    
    CLRF 0x89	; Setting ANSELH to LOW for PORTB digital I/O    
    CLRF 0x88	; Setting ANSEL to LOW for PORTA digital I/O    
        
    BCF 0x03,6	; Sets Bank 0    
    BCF 0x03,5	; Sets Bank 0    
    GOTO Main    


Main:    
    CALL ButtonPress	; Determine which button is active
    
    MOVF noteIndex,W	; Move note index into W
    XORLW 0xFF		; Compare note index with 0xFF
    BTFSC 0x03,2	; Check Zero flag
    GOTO SilentOutput	; If noteIndex = 0xFF, remain silent
    
    MOVF noteIndex,W	; Move note index into W
    CALL LookupTable	; Get delay value from lookup table
    MOVWF outCount	; Store delay value
    
    MOVLW 0x01		; Select RA0
    XORWF 0x05,1	; Toggle RA0
    
    CALL OutDelay	; Wait for half cycle
    
    GOTO Main		; Repeat program
    
ButtonPress:    
    CLRF keyLow		; Clearing lower note status bits
    CLRF keyHigh	; Clearing higher note status bits


; Checks Row 4 of the 4x4 matrix
    BCF 0x03,6		; Sets Bank 1
    BSF 0x03,5		; Sets Bank 1
    MOVLW 0xF7		; Sets RB3 as output LOW, rest of PORTB inputs
    MOVWF 0x86		; Sending value to TRISB
    BCF 0x03,6		; Sets Bank 0
    BCF 0x03,5		; Sets Bank 0

; Checks each column 1-4
    BTFSS 0x06,4	; Checks Column 1 for '*' key being pressed
    BSF keyHigh,4	; Setting note index 12 status bit

    BTFSS 0x06,5	; Checks Column 2 for '0' key being pressed
    BSF keyHigh,5	; Setting note index 13 status bit

    BTFSS 0x06,6	; Checks Column 3 for '#' key being pressed
    BSF keyHigh,6	; Setting note index 14 status bit

    BTFSS 0x06,7	; Checks Column 4 for 'D' key being pressed
    BSF keyHigh,7	; Setting note index 15 status bit


; Checks Row 3 of the 4x4 matrix
    BCF 0x03,6		; Sets Bank 1
    BSF 0x03,5		; Sets Bank 1
    MOVLW 0xFB		; Sets RB2 as output LOW, rest of PORTB inputs
    MOVWF 0x86		; Sending value to TRISB
    BCF 0x03,6		; Sets Bank 0
    BCF 0x03,5		; Sets Bank 0

; Checks each column 1-4
    BTFSS 0x06,4	; Checks Column 1 for '7' key being pressed
    BSF keyHigh,0	; Setting note index 8 status bit

    BTFSS 0x06,5	; Checks Column 2 for '8' key being pressed
    BSF keyHigh,1	; Setting note index 9 status bit

    BTFSS 0x06,6	; Checks Column 3 for '9' key being pressed
    BSF keyHigh,2	; Setting note index 10 status bit

    BTFSS 0x06,7	; Checks Column 4 for 'C' key being pressed
    BSF keyHigh,3	; Setting note index 11 status bit


; Checks Row 2 of the 4x4 matrix
    BCF 0x03,6		; Sets Bank 1
    BSF 0x03,5		; Sets Bank 1
    MOVLW 0xFD		; Sets RB1 as output LOW, rest of PORTB inputs
    MOVWF 0x86		; Sending value to TRISB
    BCF 0x03,6		; Sets Bank 0
    BCF 0x03,5		; Sets Bank 0

; Checks each column 1-4
    BTFSS 0x06,4	; Checks Column 1 for '4' key being pressed
    BSF keyLow,4	; Setting note index 4 status bit

    BTFSS 0x06,5	; Checks Column 2 for '5' key being pressed
    BSF keyLow,5	; Setting note index 5 status bit

    BTFSS 0x06,6	; Checks Column 3 for '6' key being pressed
    BSF keyLow,6	; Setting note index 6 status bit

    BTFSS 0x06,7	; Checks Column 4 for 'B' key being pressed
    BSF keyLow,7	; Setting note index 7 status bit


; Checks Row 1 of the 4x4 matrix
    BCF 0x03,6		; Sets Bank 1
    BSF 0x03,5		; Sets Bank 1
    MOVLW 0xFE		; Sets RB0 as output LOW, rest of PORTB inputs
    MOVWF 0x86		; Sending value to TRISB
    BCF 0x03,6		; Sets Bank 0
    BCF 0x03,5		; Sets Bank 0

; Checks each column 1-4
    BTFSS 0x06,4	; Checks Column 1 for '1' key being pressed
    BSF keyLow,0	; Setting note index 0 status bit

    BTFSS 0x06,5	; Checks Column 2 for '2' key being pressed
    BSF keyLow,1	; Setting note index 1 status bit

    BTFSS 0x06,6	; Checks Column 3 for '3' key being pressed
    BSF keyLow,2	; Setting note index 2 status bit

    BTFSS 0x06,7	; Checks Column 4 for 'A' key being pressed
    BSF keyLow,3	; Setting note index 3 status bit

Test_D:
    BTFSS keyHigh,7	; Test if D is pressed
    GOTO Test_Hash	; If not, moves to the next priority
    GOTO Note15		; D = highest note

Test_Hash:
    BTFSS keyHigh,6	; Test if # is pressed
    GOTO Test_0
    GOTO Note14

Test_0:
    BTFSS keyHigh,5	; Test if 0 is pressed
    GOTO Test_Star
    GOTO Note13

Test_Star:
    BTFSS keyHigh,4	; Test if * is pressed
    GOTO Test_C
    GOTO Note12

Test_C:
    BTFSS keyHigh,3	; Test if C is pressed
    GOTO Test_9
    GOTO Note11

Test_9:
    BTFSS keyHigh,2	; Test if 9 is pressed
    GOTO Test_8
    GOTO Note10

Test_8:
    BTFSS keyHigh,1	; Test if 8 is pressed
    GOTO Test_7
    GOTO Note9

Test_7:
    BTFSS keyHigh,0	; Test if 7 is pressed
    GOTO Test_B
    GOTO Note8

Test_B:
    BTFSS keyLow,7	; Test if B is pressed
    GOTO Test_6
    GOTO Note7

Test_6:
    BTFSS keyLow,6	; Test if 6 is pressed
    GOTO Test_5
    GOTO Note6

Test_5:
    BTFSS keyLow,5	; Test if 5 is pressed
    GOTO Test_4
    GOTO Note5

Test_4:
    BTFSS keyLow,4	; Test if 4 is pressed
    GOTO Test_A
    GOTO Note4

Test_A:
    BTFSS keyLow,3	; Test if A is pressed
    GOTO Test_3
    GOTO Note3

Test_3:
    BTFSS keyLow,2	; Test if 3 is pressed
    GOTO Test_2
    GOTO Note2

Test_2:
    BTFSS keyLow,1	; Test if 2 is pressed
    GOTO Test_1
    GOTO Note1

Test_1:
    BTFSS keyLow,0	; Test if 1 is pressed
    GOTO Silent
    GOTO Note0

	
Silent:			; No switch active    
    MOVLW 0xFF		; 0xFF represents no note
    MOVWF noteIndex	; Store silent value
    RETURN    

	
Note15:
    MOVLW 0x0F		; D = Note 16 = D5
    MOVWF noteIndex
    RETURN

Note14:
    MOVLW 0x0E		; # = Note 15 = C5
    MOVWF noteIndex
    RETURN

Note13:
    MOVLW 0x0D		; 0 = Note 14 = B4
    MOVWF noteIndex
    RETURN

Note12:
    MOVLW 0x0C		; * = Note 13 = A4
    MOVWF noteIndex
    RETURN

Note11:
    MOVLW 0x0B		; C = Note 12 = G4
    MOVWF noteIndex
    RETURN

Note10:
    MOVLW 0x0A		; 9 = Note 11 = F4
    MOVWF noteIndex
    RETURN

Note9:
    MOVLW 0x09		; 8 = Note 10 = E4
    MOVWF noteIndex
    RETURN

Note8:
    MOVLW 0x08		; 7 = Note 9 = D4
    MOVWF noteIndex
    RETURN

Note7:    
    MOVLW 0x07		; Note index 7 - C4
    MOVWF noteIndex    
    RETURN    
    
Note6:    
    MOVLW 0x06		; Note index 6 - B3
    MOVWF noteIndex    
    RETURN    
    
Note5:    
    MOVLW 0x05		; Note index 5 - A3
    MOVWF noteIndex    
    RETURN    
    
Note4:    
    MOVLW 0x04		; Note index 4 - G3
    MOVWF noteIndex    
    RETURN    
    
Note3:    
    MOVLW 0x03		; Note index 3 - F3
    MOVWF noteIndex    
    RETURN    
    
Note2:    
    MOVLW 0x02		; Note index 2 - E3
    MOVWF noteIndex    
    RETURN    
    
Note1:    
    MOVLW 0x01		; Note index 1 - D3
    MOVWF noteIndex    
    RETURN    
    
Note0:    
    MOVLW 0x00		; Note index 0 - C3
    MOVWF noteIndex    
    RETURN    

SilentOutput:
    BCF 0x05,0		; Set RA0 LOW
    GOTO Main		; Continue checking switches

LookupTable:    
    MOVF noteIndex,W	; Move note index into W
    ADDWF PCL,1		; Add note index to program counter
    
    RETLW 0xEE		; 0  - Key 1 - C3
    RETLW 0xD4		; 1  - Key 2 - D3
    RETLW 0xBD		; 2  - Key 3 - E3
    RETLW 0xB2		; 3  - Key A - F3
    RETLW 0x9F		; 4  - Key 4 - G3
    RETLW 0x8E		; 5  - Key 5 - A3
    RETLW 0x7E		; 6  - Key 6 - B3
    RETLW 0x77		; 7  - Key B - C4
    RETLW 0x6A		; 8  - Key 7 - D4
    RETLW 0x5E		; 9  - Key 8 - E4
    RETLW 0x59		; 10 - Key 9 - F4
    RETLW 0x4F		; 11 - Key C - G4
    RETLW 0x47		; 12 - Key * - A4
    RETLW 0x3F		; 13 - Key 0 - B4
    RETLW 0x3B		; 14 - Key # - C5
    RETLW 0x35		; 15 - Key D - D5


OutDelay:    
    MOVLW 0x04		; Load inner delay count
    MOVWF inCount	; Store inner delay count
    
InDelay:                         
    DECFSZ inCount,1	; Decrement inner count
    GOTO InDelay	; Repeat until inner count reaches zero
    
    DECFSZ outCount,1	; Decrement lookup delay count
    GOTO OutDelay	; Repeat outer delay
    
    RETURN		; Return when delay is complete
    
End