.include "constants.inc"
.include "header.inc"

;   After 16 bytes the code segment starts
.segment "CODE"

;   These handlers are interrupt vectors. 
;   These can be called to interrupt the NES and perform a different action, instead of continuing to fetch and execute bytes in sequence.

;   IRQ vector is for interrupt requests. This can be triggered by the NES sound processor or certain types of cartridge hardware
.proc irq_handler
  ;   RTI stands for Return from Interrupt. Basically just tells it to leave the interrupt vector and go back.  
  RTI
.endproc

;   NMI vector is for when the PPU starts preparing for the next frame of graphics. Gets called 60 times a second (basically pre frame draw functions).
.proc nmi_handler
  ;   Copies memory from $0200 till $02ff to the OAM (Object Attribute Memory). This is used to copy sprite sheets into data.
  LDA #$00
  STA OAMADDR
  LDA #$02
  STA OAMDMA
  RTI
.endproc

;   See reset.asm
.import reset_handler

.export main
.proc main
  ;   Loads memory adress 2002 (PPUSTATUS) into register X which gives info about current PPU status.
  ;   Also has the extra benefit of resetting address latch, causing any PPUADDR (memory address 2006/2007) to be the high byte of the address.
  ;   This helps ensure that the two writes PPUADDR needs always happen, instead of it being cut off after 1 write.
  LDX PPUSTATUS
  ;   Select PPU address $3f00 (selecting is done with memory address 2006 (PPUADDR)).
  ;   Setting high byte to $3f (ensured by PPUSTATUS) and low byte to $00 to get $3f00.
  ;   $3f00 is where palettes begin, so we start loading in tileset.chr after this.
  LDX #$3f
  STX PPUADDR
  LDX #$00
  STX PPUADDR

  ;   Sets X to 0.
  LDX #$00
LoopStart:
  ;   Increments X by 1. Basically the index in a for loop
  INX
  ;   If X loops to 0 after 255 cycles, it will have the C (carry) flag. With the carry flag BNE will not be triggered and the rest gets ran.
  BNE LoopStart

  ;   Fill in entire palette
  LDA #$05
  STA PPUDATA
  LDA #$05
  STA PPUDATA
  LDA #$05
  STA PPUDATA
  LDA #$05
  STA PPUDATA
  ;   Write sprite sheet data into $0200-$02ff
  LDA #$70
  STA $0200 ; Y-coordinate of first sprite
  LDA #$00
  STA $0201 ; Tile number of first sprite
  LDA #$00
  STA $0202 ; Attributes of first sprite
  LDA #$80
  STA $0203 ; X-coordinate of first sprite


  ;   Writes $05 into PPU address $3f00 using PPUDATA (memory address 2007).
  ;   Colour PPU bytes can be found here https://famicom.party/processed_images/7b00b771a60df0e500.png (currently $05 for red).
  ; LDA #$05
  ; STA PPUDATA
  ;   Sets PPUMASK options for drawing using 8 bit flags. See what each bit does here: https://images2.imgbox.com/5a/fe/QmAgRvye_o.png
  ;   Bit flags go from right to left. Current option enables left/right edge background/foreground, and background/foreground itself.
  LDA #%00011110
  STA PPUMASK
;   Infinite loop to keep CPU busy
forever:
  JMP forever
.endproc

;   Ensures that the vector interrupt handlers are in the correct memory addresses.
;   The memory addresses are  $fffa-$fffb : NMI Handler
;                             $fffc-$fffd : Reset Handler
;                             $fffe-$ffff : IRQ Handler 
.segment "VECTORS"
.addr nmi_handler, reset_handler, irq_handler

.segment "CHARS"
.incbin "tileset.chr"

.segment "STARTUP"
