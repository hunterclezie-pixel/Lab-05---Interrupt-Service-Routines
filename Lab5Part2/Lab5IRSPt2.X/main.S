// Hunter Clezie
// RCET3375
// Lab5ISRPt2
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
    MOVLW 0x11	; Setting RB4 and RB0 as inputs
    MOVWF 0x86	; Setting TRISB
    CLRF 0x85	; Setting TRISA on reset to LOW, making PORTA an output
    CLRF 0x87	; Setting TRISC on reset to LOW, making PORTC an output
    BCF 0x81,0	; Making PORTB have weak pull-ups
    BCF 0x81,6	; INTEDG = 0, interrupt on falling edge
    MOVLW 0x10	; Enabling interrupt-on-change for RB4
    MOVWF 0x96	; Setting IOCB4
        
    BSF 0x03,6	; Sets Bank 3    
    BSF 0x03,5	; Sets Bank 3    
    CLRF 0x89	; Setting ANSELH to LOW for PORTB digital I/O    
    CLRF 0x88	; Setting ANSEL to LOW for PORTA digital I/O    
        
    ; Interrupt Section
    BCF 0x03,6	; Sets Bank 0    
    BCF 0x03,5	; Sets Bank 0
    BCF INTCON,0    ; Clearing PORTB change interrupt flag bit
    BCF INTCON,1    ; Clearing external interrupt flag INTF
    BSF INTCON,3    ; Enabling The PORTB change enable bit RBIE
    BSF INTCON,4    ; Enabling RB0 external interrupt INTE
    BSF INTCON,7    ; Enabling global interrupts GIE

    GOTO Main    

Main:    
    MOVLW 0x01		; Loading bit 0
    XORWF PORTA,F	; Toggling RA0 monitoring pin
    GOTO Main		; Repeat program
    
ISRHandler:
    MOVWF W_TEMP	; Saving W register
    SWAPF STATUS,W	; Moving STATUS into W
    CLRF STATUS		; Selecting Bank 0
    MOVWF STATUS_TEMP	; Saving STATUS register
    BTFSC INTCON,0	; Checking if PORTB change interrupt occurred 
    GOTO IncrementISR
    BTFSC INTCON,1	; Checking if RB0 external interrupt occurred
    GOTO ClearISR
    GOTO LeaveISR

IncrementISR:
    MOVF PORTB,W	; Reading PORTB to resolve IOC mismatch
    INCF PORTC,F	; Incrementing PORTC binary count
    BCF INTCON,0	; Clearing PORTB change interrupt flag RBIF
    GOTO LeaveISR
    
ClearISR:
    CLRF PORTC		; Clearing PORTC binary count
    BCF INTCON,1	; Clearing external interrupt flag INTF
    GOTO LeaveISR

LeaveISR:
    SWAPF STATUS_TEMP,W	; Restoring saved STATUS value
    MOVWF STATUS	; Restoring STATUS register
    SWAPF W_TEMP,F	; Preparing saved W value
    SWAPF W_TEMP,W	; Restoring W register
    RETFIE		; Returning from interrupt

END