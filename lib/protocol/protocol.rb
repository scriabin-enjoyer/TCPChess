# frozen_string_literal: true

module MyGameServer
  # Namespace for all Protocol related features. Game applications that want
  # to add a game to the Server should implement their protocol in this
  # module (message generators, parsers) in their own class/module, and
  # register their top-level type as a constant in this file, at the top of
  # this module. Additionally, the methods below are made available to all
  # interested users.
  module Protocol
    # Register types here
    SYSTEM_T = 0xFF
    CHESS_T = 0x01

    # Useful constants
    MIN_MESSAGE_SIZE = 3
    MIN_LENGTH_VALUE = 1

    # Custom exceptions
    class ProtocolError < StandardError; end
    class BadHeader < ProtocolError; end

    module_function

    # Reads in raw byte string returns hash containing top level type,
    # corresponding op-code, and the raw binary payload if it exists. Returns
    # nil if there is not enough structured data to emit a full protocol
    # message.
    # NOTE: Callers make sure to rescue BadHeader/ProtocolError
    # NOTE: Callers must remember to slice out consumed read buffers themselves
    def parse_tltv(data)
      return if data.bytesize < MIN_MESSAGE_SIZE

      # Get Type1, Length, Type2
      t1, l, t2 = unpack_header(data)

      # Length = length(Type2) + length(Value),
      # so 2 = length(Type1) + length(Length)
      total_size = l + 2
      return if data.bytesize < total_size

      v = extract_raw_value(data, l)

      # Don't unpack the payload here since it will require specific
      # interpretation at a higher level
      { type1: t1, type2: t2, bytes_read: total_size, raw_value: v }
    end

    def unpack_header(data)
      # Avoid unpack when you can, getbyte() is much more performant
      t1, l, t2 = data.getbyte(0), data.getbyte(1), data.getbyte(2)
      raise BadHeader, "0 length message" if l < MIN_LENGTH_VALUE
      raise BadHeader, "Received Invalid Protocol ID #{t1}" unless valid_protocol?(t1)

      [t1, l, t2]
    end

    def valid_protocol?(type)
      type == SYSTEM_T || type == CHESS_T
    end

    # Extract Value field using l (l = length(t2) + length(value), with
    # length(t2) always 1 byte)
    def extract_raw_value(data, length)
      v_len = length - 1
      data.byteslice(3, v_len)
    end
  end
end
