# frozen_string_literal: true

# Postel's law: “be conservative in what you send, be liberal in what you
# accept”

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
    MAX_LENGTH_VALUE = 255
    MAX_VALUE_SIZE = 254

    # Custom exceptions
    class ProtocolError < StandardError; end
    class ProtocolViolation < ProtocolError; end

    # Event objects emitted by the parser and EventHandlers
    # payload field represents the trailing "TV" in TLTV, i.e. the application
    # specific data as a binary encoded string
    class Event
      attr_reader :type1, :length, :payload, :bytesize

      # Parses data from wire, Returns instance of self or nil if not enough
      # data to parse a full protocol message
      def self.from_wire(data)
        return if data.bytesize < MIN_MESSAGE_SIZE

        length = data.getbyte(1)
        total_size = length + 2
        return if data.bytesize < total_size

        type1 = data.getbyte(0)
        payload = data.byteslice(2, length)
        new(type1: type1, length: length, payload: payload)
      end

      def initialize(type1:, length:, payload:)
        raise ProtocolViolation, "Invalid Protocol ID: #{type1}" unless Protocol.valid_protocol?(type1)
        raise ProtocolViolation, "Invalid length field" unless Protocol.valid_length_field?(length)
        unless length == payload.bytesize
          raise ProtocolViolation, "Length value (#{length}) does not equal payload size (#{payload.bytesize})"
        end

        @type1 = type1
        @length = length
        @payload = payload.freeze
        @bytesize = length + 2
      end

      def to_wire
        [@type1, @length, @payload].pack("CCa*")
      end
    end

    module_function

    # Receives a binary string (read buffer).
    # Returns Protocol::Event object
    # Returns nil if there is not enough data to parse a full length protocol
    # message.
    # NOTE: raises ProtocolViolation on 0-length messages
    # NOTE: raises ProtocolViolation on invalid Type1 field
    # NOTE: Does not mutate data; callers must remember to slice out consumed
    # read buffers themselves
    def parse_tlv(data)
      Event.from_wire(data)
    end

    def test_parse
      require 'benchmark/ips'
      data = "\xff\x01\x01".b
      Benchmark.ips do |ips|
        ips.report("parse") { parse_tlv data }
      end
    end

    def serialize(event)
      event.to_wire
    end

    def valid_protocol?(type)
      type == SYSTEM_T || type == CHESS_T
    end

    def valid_msg_size?(msg_bytesize)
      msg_bytesize.between?(MIN_MESSAGE_SIZE, MAX_MESSAGE_SIZE)
    end

    def valid_length_field?(length)
      length.between?(MIN_LENGTH_VALUE, MAX_LENGTH_VALUE)
    end
  end
end
