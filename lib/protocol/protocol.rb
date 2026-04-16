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
    MAX_VALUE_SIZE = 254

    # Custom exceptions
    class ProtocolError < StandardError; end
    class ProtocolViolation < ProtocolError; end

    module_function

    # Event Strucutre:
    # {
    #   :type => Type1 field (Integer),
    #   :length => Length field (Integer),
    #   :payload => Type2, Value fields (Binary String)
    # }

    # Receives a binary string (read buffer).
    # Returns array: first element a hash representing the message data, and
    # the second element an Integer representing the number of bytes read.
    # Returns nil if there is not enough data to parse a full length protocol
    # message.
    # NOTE: raises ProtocolViolation on 0-length messages
    # NOTE: raises ProtocolViolation on invalid Type1 field
    # NOTE: Does not mutate data; callers must remember to slice out consumed
    # read buffers themselves
    def parse_tlv(data)
      return if data.bytesize < MIN_MESSAGE_SIZE

      type, length = unpack_header(data)
      total_size = length + 2
      return if data.bytesize < total_size

      payload = data.byteslice(2, length)
      [{ type: type, length: length, payload: payload }, total_size]
    end

    # Receives event-structured hash { type:, length:, payload: }
    # Returns a serialized binary string representing the hash.
    # NOTE: raises ProtocolViolation on invalid message size
    def serialize_tlv(msg)
      data = msg[:message]
      type = data[:type]
      length = data[:length]
      payload = data[:payload]
      bdata = [type, length, payload].pack("CCa*")
      raise ProtocolViolation, "Invalid message size" unless valid_msg_size?(bdata.bytesize)

      bdata
    end

    private

    def unpack_header(data)
      type, length = data.getbyte(0), data.getbyte(1)
      raise ProtocolViolation, "0 length message" if length < MIN_LENGTH_VALUE
      raise ProtocolViolation, "Received Invalid Protocol ID #{type}" unless valid_protocol?(type)

      [type, length]
    end

    def valid_protocol?(type)
      type == SYSTEM_T || type == CHESS_T
    end

    def valid_msg_size?(length)
      length.between?(MIN_MESSAGE_SIZE, MAX_MESSAGE_SIZE)
    end
  end
end
