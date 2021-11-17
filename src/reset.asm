.include "constants.inc"

;   Segment needs to be set again so compiler knows which segment this code belongs to.
.segment "CODE"
;   Imports main for the jump later
.import main
;   Exports the reset handler for the main file to import
.export reset_handler
;   Reset vector is for when the system is first turned on, or the user presses reset on the console.
.proc reset_handler
  ;   Set Interrupt Ignore Bit. This ensures anything below doesn't trigger the IRQ Handler  
  SEI
  ;   Clear Decimal Mode Bit. This disables binary-coded decimals on the 6502? Not really needed, but is best practice to disable in case it does have that option.
  CLD
  LDX #$00
  STX PPUCTRL
  STX PPUMASK
;   Waits for 30000 cycles for a stable PPUSTATUS (memory address 2002)
vblankwait:
  BIT PPUSTATUS
  BPL vblankwait

  ;   Enables NMI in the PPUMASK and PPUCTRL memory addresses
  LDA #%10010000
  STA PPUCTRL
  LDA #%00011110
  STA PPUMASK

  ;   Jumps to .proc main after a stable PPUSTATUS
  JMP main
.endproc