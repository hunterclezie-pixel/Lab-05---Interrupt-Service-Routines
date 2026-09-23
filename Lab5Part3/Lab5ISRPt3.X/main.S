// Hunter Clezie
// RCET3375
// Lab5ISRPt3
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
    W_TEMP      EQU 0x70 ; Used as part of the temporary hold for save/restore
    STATUS_TEMP EQU 0x71 ; Used as part of the temporary hold for save/restore
    PreviousB   EQU 0x20 ; Stores the previous PORTB value
    CurrentB    EQU 0x21 ; Stores the current PORTB value
    ChangedB    EQU 0x22 ; Stores which PORTB bits change
 
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

    BCF 0x03,6	; Sets Bank 1
    BSF 0x03,5	; Sets Bank 1
    MOVLW 0xFF	; Setting RB0-RB7 as inputs
    MOVWF 0x86	; Setting TRISB
    CLRF 0x85	; Setting TRISA on reset to LOW, making PORTA an output
    CLRF 0x87	; Setting TRISC on reset to LOW, making PORTC an output
    MOVLW 0xFF	; Enabling interrupt-on-change for PORTB
    MOVWF 0x96	; Setting IOC on RB0-RB7
        
    BSF 0x03,6	; Sets Bank 3    
    BSF 0x03,5	; Sets Bank 3    
    CLRF 0x89	; Setting ANSELH to LOW for PORTB digital I/O    
    CLRF 0x88	; Setting ANSEL to LOW for PORTA digital I/O    
        
    ; Interrupt Section
    BCF 0x03,6	; Sets Bank 0    
    BCF 0x03,5	; Sets Bank 0
    MOVF PORTB,W	; Reading initial PORTB state
    MOVWF PreviousB	; Saving initial PORTB comparison state
    BCF INTCON,0    ; Clearing PORTB change interrupt flag bit
    BCF INTCON,1    ; Clearing external interrupt flag INTF
    BSF INTCON,3    ; Enabling The PORTB change enable bit RBIE
    BCF INTCON,4    ; Disabling RB0 external interrupt INTE
    BSF INTCON,7    ; Enabling global interrupts GIE

    GOTO Main    

Main:    
    GOTO Main		; Repeat program
    
ISRHandler:
    MOVWF W_TEMP	; Saving W register
    SWAPF STATUS,W	; Moving STATUS into W
    CLRF STATUS		; Selecting Bank 0
    MOVWF STATUS_TEMP	; Saving STATUS register
    BTFSC INTCON,0	; Checking if PORTB change interrupt occurred 
    GOTO ChangeISR
    GOTO LeaveISR

ChangeISR:
    MOVF PORTB,W	; Reading current PORTB and resolving IOC mismatch
    MOVWF CurrentB	; Saving current PORTB state
    XORWF PreviousB,W	; Comparing current and previous PORTB states
    MOVWF ChangedB	; Saving which bits changed
    MOVF CurrentB,W	; Updating previous PORTB state
    MOVWF PreviousB	
    BCF INTCON,0	; Clearing PORTB change interrupt flag RBIF
    CALL LookUpTable	; Finding highest priority changed pin
    MOVWF PORTA		; Displaying pin number on RA2-RA0
    GOTO LeaveISR
    
LookUpTable:
    BTFSC ChangedB,7
    RETLW 0x07

    BTFSC ChangedB,6
    RETLW 0x06

    BTFSC ChangedB,5
    RETLW 0x05

    BTFSC ChangedB,4
    RETLW 0x04

    BTFSC ChangedB,3
    RETLW 0x03

    BTFSC ChangedB,2
    RETLW 0x02

    BTFSC ChangedB,1
    RETLW 0x01

    BTFSC ChangedB,0
    RETLW 0x00

    RETLW 0x00

LeaveISR:
    SWAPF STATUS_TEMP,W	; Restoring saved STATUS value
    MOVWF STATUS	; Restoring STATUS register
    SWAPF W_TEMP,F	; Preparing saved W value
    SWAPF W_TEMP,W	; Restoring W register
    RETFIE		; Returning from interrupt

END