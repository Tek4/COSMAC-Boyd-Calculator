# Seiko 80C49 Register Usage
Seiko MTP102 line printer used in Boyd Calculator

## Register Usage

### F0 flag

### F1 flag Data received
Set when external interrupt triggers reading external data on P1.

### R4 External data
Stores value read from P1 upon last external interrupt.


## Internal RAM Usage

### @008H–@017H Program Counter Stack
Eight register pairs, allows up to eight nested subroutine calls. Each call saves the 12-bit Program Counter and upper 4-bits of PSW (flag bits). Stack grows upward.

### @020H
### @021H
### @022H Line width
Appears to store number of characters per line.
### @023H
### @024H


### @051H–@055H Character dot-matrix data
Five columns, left-to-right. Seven rows (bits 0 through 6, top-to-bottom).

### @058H–@07FH Line Buffer (40 characters)