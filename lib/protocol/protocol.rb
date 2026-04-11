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
    MAX_MESSAGE_SIZE = 257
    MIN_LENGTH_VALUE = 1

    # Custom exceptions
    class ProtocolError < StandardError; end
    class BadHeader < ProtocolError; end

    module_function

    # Reads data (read buffer) and returns a hash containing the top level
    # type, the length, and a payload which consists of the raw bytes that
    # comprise the Type2 and Value fields of the protocol. These fields must be
    # parsed at a higher level.
    # NOTE: Callers make sure to rescue BadHeader/ProtocolError
    # NOTE: Callers must remember to slice out consumed read buffers themselves
    def parse_tlv(data)
      return if data.bytesize < MIN_MESSAGE_SIZE

      # Get uint8 values for Type1 field and Length field
      type, length = unpack_header(data)

      # Length field value = bytesize(Type2 field) + bytesize(Value field)
      # -> bytesize(Type1 field) + bytesize(Length field) = 1 + 1 = 2
      total_size = length + 2
      return if data.bytesize < total_size

      payload = data.byteslice(2, length)

      # Don't unpack the payload here since it will require specific
      # interpretation at a higher level
      {
        msg_len: total_size,
        message: { type: type, length: length, payload: payload }
      }
    end

    # expects a hash with the same format as the parse_tltv method generates
    def serialize_tlv(msg)
      msg_len, data = msg[:msg_len], msg[:message]
      type = data[:type]
      length = data[:length]
      # this should be a byte string
      payload = data[:payload]
      # In a production environment, this shouldn't ever raise, and in fact
      # this method shouldn't even raise exceptions anywhere
      raise BadHeader, "Message size too big" if msg_len > MAX_MESSAGE_SIZE
      raise BadHeader, "Invalid length" if length != payload.bytesize

      [type, length, payload].pack("CCCa*")
    end

    def unpack_header(data)
      # Avoid unpack when you can, getbyte() is much more performant
      type, length = data.getbyte(0), data.getbyte(1)
      raise BadHeader, "0 length message" if length < MIN_LENGTH_VALUE
      raise BadHeader, "Received Invalid Protocol ID #{type}" unless valid_protocol?(type)

      [type, length]
    end

    def valid_protocol?(type)
      type == SYSTEM_T || type == CHESS_T
    end
  end
end
