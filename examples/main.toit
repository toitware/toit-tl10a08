// Copyright (C) 2022 Toitware ApS.
// Use of this source code is governed by a Zero-Clause BSD license that can
// be found in the EXAMPLES_LICENSE file.

/**
Demonstrates the use of the driver using a common UART-RS485 transceiver, such as the
  SP3485, used in the BOB-10124 transceiver breakout board.
*/

import gpio
import log
import tl19a08
import rs485
import modbus

RX ::= 17
TX ::= 16

main:
  log.set_default (log.default.with_level log.INFO_LEVEL)

  pin_rx := gpio.Pin RX
  pin_tx := gpio.Pin TX

  rs485_bus := rs485.Rs485
      --rx=pin_rx
      --tx=pin_tx
      --baud_rate=tl19a08.Tl19a08.BAUD_RATE
  bus := modbus.Modbus.rtu rs485_bus

  // Assume that the sensor is the only one on the bus.
  channels := tl19a08.Tl19a08.detect bus

  // Print the current status of all channels.
  print channels.read

  // Open channel 1
  channels.open 1

  print (channels.read 1)  // Print the status of channel 1. => true.
  print channels[1]

  // Open channel 2 for 2 seconds.
  channels.open --s=2 2

  sleep --ms=3_000

  // Open channel 3 and close all other channels.
  channels.open --single 3

  print channels[3]  // => true.

  // Toggle channel 3.
  channels.toggle 3

  print channels[3] // => false

  // Set channel 4 to open.
  channels[4] = true

  // Close all channels.
  channels.close --all
