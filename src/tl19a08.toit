// Copyright (C) 2022 Toitware ApS. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be found
// in the LICENSE file.

import modbus
import modbus.rs485 as modbus
import rs485
import gpio

/**
A driver for the TL19A08 8-channel TTL output module.
*/
class Tl19a08:
  static DEFAULT_UNIT_ID ::= 1
  static BAUD_RATE ::= 9600

  static UNIT_ID_ADDRESS_ ::= 0xFF

  static OPEN_COMMAND_ ::= 0x01
  static CLOSE_COMMAND_ ::= 0x02
  static TOGGLE_COMMAND_ ::= 0x03
  static LATCH_COMMAND_ ::= 0x04
  static MOMENTARY_COMMAND_ ::= 0x05  // Unused: Equivalent to a delay-command of 1s.
  static DELAY_COMMAND_ ::= 0x06

  static ALL_ADDRESS_ ::= 0x00
  static OPEN_ALL_ ::= 0x07
  static CLOSE_ALL_ ::= 0x08

  registers_/modbus.HoldingRegisters

  /**
  Creates a new Tl19a08 driver.

  The given Modbus $station must be a TL19A08 device.
  */
  constructor station/modbus.Station:
    registers_ = station.holding_registers

  /**
  Creates a new Tl19a08 driver.

  Uses $detect_unit_id to find the unit id of the TL19A08 device.
  The TL19A08 device must be the only device on the bus.
  */
  constructor.detect bus/modbus.Modbus:
    id := detect_unit_id bus
    return Tl19a08 (bus.station id)

  /**
  Reads the unit id (also known as "server address", or "station address") from the connected sensor.

  Note that only one unit must be on the bus when performing this action.
  */
  static detect_unit_id bus/modbus.Modbus -> int:
    broadcast_station := bus.station 0xFF
    return broadcast_station.holding_registers.read_single --address=UNIT_ID_ADDRESS_

  /**
  Reads the current status of the given $channel.

  The $channel must be in the range 1 to 8 (matching the labels on the module).
  */
  read channel/int -> bool:
    if not 1 <= channel <= 8: throw "INVALID_ARGUMENT"
    return (registers_.read_single --address=channel) != 0

  /**
  Reads the current status of all channels.

  Returns a list of booleans, one for each channel.
  */
  read -> List:
    values := registers_.read_many --address=0x01 --register_count=8
    return values.map: it != 0

  /**
  Returns the current value of the given $channel.

  This function is an alias for $(read channel).
  */
  operator [] channel/int -> bool:
    return read channel

  /**
  Sets the given $channel to the given $value.

  If $value is true opens the channel, otherwise closes it.

  See $open and $close.
  */
  write channel/int value/bool:
    if not 1 <= channel <= 8: throw "INVALID_ARGUMENT"
    if value: open channel
    else: close channel

  /**
  Sets the given $channel to the given $value.

  This function is an alias for $write.
  */
  operator []= channel/int value/bool -> none:
    write channel value

  /**
  Opens the given $channel.

  If the mode-selection pads M1 are disconnected (default) sets the channel to low.
  If the mode-selection pads M1 are connected, sets the channel to high.
  */
  open channel/int -> none:
    if not 1 <= channel <= 8: throw "INVALID_ARGUMENT"
    registers_.write_single --address=channel (OPEN_COMMAND_ << 8)

  /**
  Closes the given $channel.

  If the mode-selection pads M1 are disconnected (default) sets the channel to high.
  If the mode-selection pads M1 are connected, sets the channel to low.
  */
  close channel/int -> none:
    if not 1 <= channel <= 8: throw "INVALID_ARGUMENT"
    registers_.write_single --address=channel (CLOSE_COMMAND_ << 8)

  /**
  Toggles the given $channel.

  If the $channel was open, closes it. If it was closed, opens it.
  */
  toggle channel/int -> none:
    if not 1 <= channel <= 8: throw "INVALID_ARGUMENT"
    registers_.write_single --address=channel (TOGGLE_COMMAND_ << 8)

  /**
  Opens only the single given $channel.

  Opens the given $channel and closes all other channels.

  See $(open channel).
  */
  open --single/bool channel/int -> none:
    if not single: throw "INVALID_ARGUMENT"
    if not 1 <= channel <= 8: throw "INVALID_ARGUMENT"
    registers_.write_single --address=channel (LATCH_COMMAND_ << 8)


  /**
  Opens the given $channel for the given $s seconds.

  The $s parameter must be in the range 0 to 255.
  A $close command can close the channel before the duration has elapsed.

  See $(open channel).
  */
  open --s/int channel/int -> none:
    if not 1 <= channel <= 8: throw "INVALID_ARGUMENT"
    if not 0 <= s <= 255: throw "INVALID_ARGUMENT"
    registers_.write_single --address=channel ((DELAY_COMMAND_ << 8) | s)

  /**
  Opens all channels.

  See $(open channel).
  */
  open --all/bool -> none:
    if not all: throw "INVALID_ARGUMENT"
    registers_.write_single --address=ALL_ADDRESS_ (OPEN_ALL_ << 8)

  /**
  Closes all channels.

  See $(close channel).
  */
  close --all/bool -> none:
    if not all: throw "INVALID_ARGUMENT"
    registers_.write_single --address=ALL_ADDRESS_ (CLOSE_ALL_ << 8)

  /**
  Changes the unit id (also known as "server address", or "station address") to the given $id.

  After this call, this current instance will be unable to communicate with the sensor (unless the chosen $id is the
    unit id that is already set). One has to create a new instance with the new station.

  The $id must be in range 1-247.
  */
  set_unit_id id/int:
    if not 1 <= id <= 247: throw "INVALID_ARGUMENT"
    registers_.write_single --address=UNIT_ID_ADDRESS_ id
