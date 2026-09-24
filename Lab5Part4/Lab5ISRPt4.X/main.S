// Hunter Clezie
// RCET3375
// Lab5ISRPt4
// https://github.com/hunterclezie-pixel/Lab-05---Interrupt-Service-Routines.git

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

; config statements should precede project file includes.
#include <xc.inc>  
    ; General Purpose Registers
    W_TEMP1      EQU 0x70 ; Used as part of the temporary hold for save/restore
    STATUS_TEMP1 EQU 0x71 ; Used as part of the temporary hold for save/restore
    ISR_STATE    EQU 0x72 ; Bit 0 shows if the 6 behavior is active
    W_TEMP2      EQU 0x73 ; Saves W for the nested 7 interrupt
    STATUS_TEMP2 EQU 0x74 ; Saves STATUS for the nested 7 interrupt

    OUT_SAVE     EQU 0x75 ; Saves outCount when 7 interrupts 6
    MID_SAVE     EQU 0x76 ; Saves midCount when 7 interrupts 6
    IN_SAVE      EQU 0x77 ; Saves inCount when 7 interrupts 6

    outCount     EQU 0x20 ; Outer delay counter
    midCount     EQU 0x21 ; Middle delay counter
    inCount      EQU 0x22 ; Inner delay counter
 
; Reset Vector at 0000h. Execution starts here after reset.
PSECT resetVect,class=CODE,delta=2
ResetVector:
    goto Setup

; Interrupt Vector
PSECT isrVect,class=CODE,delta=2
InterruptVector:
    GOTO ISRHandler

; Main code section starts at 0008h. User code goes here.
PSECT code,class=CODE,delta=2
 
Setup:
    BCF 0x03,6	; Sets Bank 0
    BCF 0x03,5	; Sets Bank 0
    CLRF 0x05	; Setting PORTA on reset to LOW
    CLRF 0x06	; Setting PORTB on reset to LOW
    CLRF 0x07	; Setting PORTC on reset to LOW
    CLRF ISR_STATE ; Clearing interrupt state

    BCF 0x03,6	; Sets Bank 1
    BSF 0x03,5	; Sets Bank 1
    MOVLW 0x03	; Setting RB0 and RB1 as inputs
    MOVWF 0x86	; Setting TRISB
    CLRF 0x85	; Setting TRISA on reset to LOW, making PORTA an output
    CLRF 0x87	; Setting TRISC on reset to LOW, making PORTC an output
    BCF 0x81,6	; INTEDG = 0, RB0 interrupt on falling edge
    MOVLW 0x02	; Enabling interrupt-on-change for RB1
    MOVWF 0x96	; Setting IOCB1
        
    BSF 0x03,6	; Sets Bank 3    
    BSF 0x03,5	; Sets Bank 3    
    CLRF 0x89	; Setting ANSELH to LOW for PORTB digital I/O    
    CLRF 0x88	; Setting ANSEL to LOW for PORTA digital I/O    
        
    ; Interrupt Section
    BCF 0x03,6	; Sets Bank 0    
    BCF 0x03,5	; Sets Bank 0
    MOVF PORTB,W    ; Reading initial PORTB state
    BCF INTCON,0    ; Clearing PORTB change interrupt flag bit
    BCF INTCON,1    ; Clearing external interrupt flag INTF
    BSF INTCON,3    ; Enabling The PORTB change enable bit RBIE
    BSF INTCON,4    ; Enabling RB0 external interrupt INTE
    BSF INTCON,7    ; Enabling global interrupts GIE

    GOTO Main    

Main: 
    MOVLW 0x31		; The DLG7137 character '1'
    MOVWF PORTC		; Displaying 1 on the DLG7137
    GOTO Main		; Main continuously displays 1
    
ISRHandler:
    BTFSC ISR_STATE,0	; Checking if the 6 behavior is active
    GOTO SaveNested	; If yes, save nested interrupt context
    
SaveNormal:
    MOVWF W_TEMP1	; Saving W register
    SWAPF STATUS,W	; Moving STATUS into W
    CLRF STATUS		; Selecting Bank 0
    MOVWF STATUS_TEMP1	; Saving STATUS register
    GOTO DetermineSource
    
SaveNested:
    MOVWF W_TEMP2	; Saving nested W register
    SWAPF STATUS,W	; Moving nested STATUS into W
    MOVWF STATUS_TEMP2	; Saving nested STATUS register
    CLRF STATUS		; Selecting Bank 0
    MOVF outCount,W	; Saving current outer delay count
    MOVWF OUT_SAVE
    MOVF midCount,W	; Saving current middle delay count
    MOVWF MID_SAVE
    MOVF inCount,W	; Saving current inner delay count
    MOVWF IN_SAVE
    GOTO NestedSource
    
DetermineSource:
    BTFSC INTCON,0	; Checking PORTB IOC flag
    GOTO CheckSeven
    BTFSC INTCON,1	; Checking RB0 external interrupt flag
    GOTO SixISR
    GOTO LeaveNormal
    
CheckSeven:
    MOVF PORTB,W	; Reading PORTB to resolve IOC mismatch
    BCF INTCON,0	; Clearing PORTB change interrupt flag RBIF
    BTFSS PORTB,1	; Checking if RB1 is LOW
    GOTO SevenISR	; If LOW, begin the 7 behavior

    ; If RB1 is HIGH, the change was a release
    BTFSC INTCON,1	; Checking if RB0 interrupt is also waiting
    GOTO SixISR
    GOTO LeaveNormal

SixISR:
    BCF INTCON,1	; Clearing external interrupt flag INTF
    BCF INTCON,4	; Disabling additional RB0 interrupts
    BSF ISR_STATE,0	; Setting the 6-active status bit
    MOVLW 0x36		; The DLG7137 character '6'
    MOVWF PORTC		; Displaying 6

    BSF INTCON,7	; Re-enabling GIE so 7 can interrupt 6
    CALL Delay2s	; Displaying 6 for approximately 2 seconds
    BCF INTCON,7	; Disabling interrupts during 6 cleanup
    BCF ISR_STATE,0	; Clearing the 6-active status bit
    BCF INTCON,1	; Clearing any RB0 events that occurred during 6
    BSF INTCON,4	; Re-enabling RB0 external interrupt

    MOVLW 0x31		; The DLG7137 character '1'
    MOVWF PORTC		; Returning display to 1

    GOTO LeaveNormal
    
SevenISR:
    MOVLW 0x37		; The DLG7137 character '7'
    MOVWF PORTC		; Displaying 7

    CALL Delay2s	; Displaying 7 for approximately 2 seconds
    MOVF PORTB,W	; Updating PORTB comparison state
    BCF INTCON,0	; Clearing any IOC produced during 7

    MOVLW 0x31		; The DLG7137 character '1'
    MOVWF PORTC		; Returning display to 1

    GOTO LeaveNormal

NestedSource:
    BTFSS INTCON,0	; Checking if IOC caused nested interrupt
    GOTO LeaveNested

    MOVF PORTB,W	; Reading PORTB to resolve IOC mismatch
    BCF INTCON,0	; Clearing PORTB change interrupt flag RBIF
    BTFSC PORTB,1	; Checking if RB1 is HIGH
    GOTO LeaveNested	; HIGH means button release
    GOTO NestedSeven

NestedSeven:
    MOVLW 0x37		; The DLG7137 character '7'
    MOVWF PORTC		; Displaying 7

    CALL Delay2s	; Displaying 7 for approximately 2 seconds
    MOVF PORTB,W	; Updating PORTB comparison state
    BCF INTCON,0	; Clearing any IOC produced during 7

    MOVLW 0x36		; The DLG7137 character '6'
    MOVWF PORTC		; Returning display to 6
    GOTO LeaveNested
    
Delay2s:
    CALL Delay500ms	; First 0.5 seconds
    CALL Delay500ms	; Second 0.5 seconds
    CALL Delay500ms	; Third 0.5 seconds
    CALL Delay500ms	; Fourth 0.5 seconds
    RETURN
    
Delay500ms:
    MOVLW 0x17		; Loading outer delay count
    MOVWF outCount

DelayOuter:
    MOVLW 0xBD		; Loading middle delay count
    MOVWF midCount

DelayMiddle:
    MOVLW 0x25		; Loading inner delay count
    MOVWF inCount

DelayInner:
    DECFSZ inCount,F	; Decrementing inner delay count
    GOTO DelayInner	; Repeating until inner count reaches zero
    DECFSZ midCount,F	; Decrementing middle delay count
    GOTO DelayMiddle	; Repeating middle delay
    DECFSZ outCount,F	; Decrementing outer delay count
    GOTO DelayOuter	; Repeating outer delay
    RETURN		; Returning from 0.5 second delay

LeaveNormal:
    SWAPF STATUS_TEMP1,W ; Restoring saved STATUS value
    MOVWF STATUS
    SWAPF W_TEMP1,F	; Preparing saved W value
    SWAPF W_TEMP1,W	; Restoring W register
    RETFIE		; Returning from interrupt
    
LeaveNested:
    MOVF OUT_SAVE,W	; Restoring outer delay count
    MOVWF outCount
    MOVF MID_SAVE,W	; Restoring middle delay count
    MOVWF midCount
    MOVF IN_SAVE,W	; Restoring inner delay count
    MOVWF inCount
    SWAPF STATUS_TEMP2,W ; Restoring nested STATUS value
    MOVWF STATUS
    SWAPF W_TEMP2,F	; Preparing nested saved W value
    SWAPF W_TEMP2,W	; Restoring nested W register
    RETFIE		; Returning to interrupted 6 behavior

END