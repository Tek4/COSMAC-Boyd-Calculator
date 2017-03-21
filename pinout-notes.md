# Seiko 80C49 pinout
Seiko MTP102 line printer used in Boyd Calculator.

Credit: [Christopher Bachmann](
https://groups.yahoo.com/neo/groups/cosmacelf/conversations/messages/20075)

Additional Resources:
 [MTP Series Technical Reference](http://sii-thermalprinters.com/pdf/manuals/MTP_series/MTP_Series_Technical_Reference.pdf)

### 6 /INT (input) /STROBE (from 1805)

### 12–19 D0–D7 BUS (output) print head/motor
* D0–D6 = print head (D0=top dot, D6=bottom dot)
* D7 = motor

### 27–34 P1.0–1.7 (input) data bus from 1805
These inputs are latched by two CD4042 four-bit latches (U6 and U7).

### 21–23 P2.0–2.2 (input) Line width (not connected)
Selects the number of characters per line:

| P2.2–2.0   | 000 | 001 | 010 | 011 | 100 | 101 | 110 | 111 |
|------------|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| Line Width |  40 |  32 |  25 |  24 |  20 |  16 |  16 |  13 |

The MCS-48 series has a pull-up device on each port pin, which causes them to read high when used as a disconnected input. With all three inputs disconnected, the width is 13 characters.

### 24 P2.3 (input) /FEED (PF Key)

### 35 P2.4 (input) pulled up (/RESET?)
I'm not very clear as to the operation of pin 35/P2.4. From the code path, it looks like it is used to cancel the current operation and start over while waiting for a strobe. If an operation times out (such as waiting for the head to move on or off the home switch) the code jumps to a "safe mode" routine which shuts off everything and then waits for this pin to go low. A low on this pin then causes a jump back to the primary initialization routine as if the /RESET line on the 80C49 was pulled low.

### 36 P2.5 (input) printer home switch

### 37 P2.6 (output) /READY (not connected)
The /READY signal is set low when the chip is ready to accept data from the host. It is immediately set high when the 80C49 jumps to the interrupt routine. This seems to be same as !PBUSY on page 5-13 of the CPU manual, or /READY on page 6-2 of the MTP manual.

### 38 P2.7 (output) /printing (not connected)
The printing status output (P2.7/pin 38) is set high normally, and then set low when the motor is running during a printing operation. I don't see a matching output in the manuals.

### 1 T0 (input) printer tachogenerator
T0 is driven by the TG waveform shaping circuit similar to figure 2–4 on page 2–8 of the MTP manual.

### 39 T1 (input) printing pulse width timing control
T1 feeds the 80C49 timer/event counter and is connected to the printing pulse width control circuit (page 2–14 in the MTP manual) or temperature/ voltage compensation circuit (page 5–12 in the CPU manual.) It looks like they used the former.

## The remaining pins are most likely used as described in the 80C49 datasheet:

### 2–3 XTAL1/XTAL2
Not TTL compatible. (Approx. 2.1 MHz in the Boyd Calculator.)
### 4 /RESET
### 5 /SS Single step input
Can be used in conjunction with ALE to "single step" the processor through each instruction.
### 7 EA External Access input
Forces program memory fetches to exteral memory. Useful for emulation and debug.
### 8 /RD
Output strobe activated during a BUS read. Can be used to enable data onto the BUS from an external device.
### 9 /PSEN
Program Store Enable. This output occurs only during a fetch to external program memory.
### 10 /WR
Output strobe during a BUS write.
### 11 ALE
Address Latch Enable. This signal occurs once during each cycle and is useful as a clock output.
### 20 Vss
Circuit GND potential.
### 25 PROG
Output strobe for 8243 I/O expander.
### 26 Vdd
+5V during operation. Low power standby pin.
### 40 Vcc
Main power supply; +5V during operation.
