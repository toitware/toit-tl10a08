// Copyright (C) 2022 Toitware ApS.
// Use of this source code is governed by a Zero-Clause BSD license that can
// be found in the EXAMPLES_LICENSE file.

/**
Tests the TL19A08 driver.

Connections:
Connect the ESP32 to the module with pins 17<->T, 16<->R.
Connect 5V to VIN and GND to GND.

Connect pins 34, 35, ... (see constant list below) to channel 1, 2, 3 ...

Run the whole test (which takes some time).

Run the same test with $LEVEL_IS_LOW set to false:
  1. unplug the power of the TL19A08 module
  2. change the value to false
  3. bridge the M1 pads
  4. plug the power again (this is when the configuration is read)
  5. run the tests again.
*/

import expect show *
import gpio
import tl19a08
import rs485
import modbus
import log

RX ::= 17
TX ::= 16

IN_PIN_NUMS ::= [
  34, 35, 32, 33, 25, 26, 27, 14
]

IN_PINS := IN_PIN_NUMS.map: gpio.Pin --input it

LEVEL_IS_LOW ::= true  // Default.
OPEN ::= LEVEL_IS_LOW ? 0 : 1
CLOSED ::= LEVEL_IS_LOW ? 1 : 0

check channels/tl19a08.Tl19a08 expected_status_bits/int:
  expected_status := List 8: (expected_status_bits & (1 << it)) != 0
  status := channels.read
  expect_equals 8 status.size
  expect_equals expected_status status

  status.size.repeat:
    pin := IN_PINS[it]
    expected := status[it] ? OPEN : CLOSED
    expect_equals expected pin.get

  status.size.repeat:
    expect_equals status[it] channels[it + 1]

main:
  log.set_default (log.default.with_level log.INFO_LEVEL)
  rs485_bus := rs485.Rs485
      --rx=gpio.Pin RX
      --tx=gpio.Pin TX
      --baud_rate=tl19a08.Tl19a08.BAUD_RATE
  bus := modbus.Modbus.rtu rs485_bus

  // Assume that the module is the only one on the bus.
  channels := tl19a08.Tl19a08.detect bus

  channels.close --all
  check channels 0b0000_0000

  channels.open --all
  check channels 0b1111_1111

  channels.close --all
  check channels 0b0000_0000

  8.repeat:
    channel_mask := 1 << it
    channel := it + 1
    print "Checking channel $channel"
    channels[channel] = true
    check channels channel_mask

    channels[channel] = false
    check channels 0b0000_0000

    channels.write channel true
    check channels channel_mask

    channels.write channel false
    check channels 0b0000_0000

    channels.toggle channel
    check channels channel_mask

    channels.toggle channel
    check channels 0b0000_0000

    channels.open --s=1 channel
    check channels channel_mask
    sleep --ms=1_100
    check channels 0b0000_0000

    channels.open --s=5 channel
    check channels channel_mask
    channels.close channel
    check channels 0b0000_0000

    channels.open --all

    channels[channel] = false
    check channels 0b1111_1111 & ~channel_mask

    channels.toggle channel
    check channels 0b1111_1111

    channels.toggle channel
    check channels 0b1111_1111 & ~channel_mask

    channels.open --single channel
    check channels channel_mask

    channels.close --all

  old_id := tl19a08.Tl19a08.detect_unit_id bus
  print "current unit id: $old_id"

  channels.set_unit_id 5
  expect_equals 5 (tl19a08.Tl19a08.detect_unit_id bus)
  channels5 := tl19a08.Tl19a08 (bus.station 5)
  expect_equals 8 channels5.read.size

  channels5.set_unit_id 6
  expect_equals 6 (tl19a08.Tl19a08.detect_unit_id bus)
  channels6 := tl19a08.Tl19a08 (bus.station 6)
  expect_equals 8 channels6.read.size

  print "Switching back to old unit id"
  channels6.set_unit_id old_id

  if old_id != 5:
    expect_throw DEADLINE_EXCEEDED_ERROR: channels5.read
  else:
    expect_throw DEADLINE_EXCEEDED_ERROR: channels6.read

  print "done"
