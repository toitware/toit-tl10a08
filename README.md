# TL19A08

Driver for the TL19A08 8-channel TTL output module.

The TL19A08 is a module that allows to control 8 digital outputs. It is
manufactured by [eletechsup](https://www.ebay.com/str/eletechsupsofficialstore).

## Description
The TL19A08 exists in two variants, differing in their input voltage. The 5V
variant takes 5V as input on VIN, the 12V version takes 6-24V as input.

The `Vo` pin of the 5V version is 5V, the `Vo` pin of the 12V version is 12V.

The 12V version can be recognized by the presence of a voltage regulator (in proximity of
the 8th output channel). The 5V version has this solder pad unpopulated.

The working current of the module is 8-13mA.

The module can be controlled through a Modbus interface, or with AT commands. By
default the module is configured to use the Modbus interface. For the AT commands one
has to bridge the 0 pins on the mode-selection pads (next to the PWR LED).

The level of the output port is low by default. It can be switched by bridging the
1 pins on the mode-selection pads.

The left-most mode selection pins (marked as M2) are unused.

## Standard configuration
The R46CA01's UART is configured for 9600, N, 8, 1. The speed can be configured via software.
