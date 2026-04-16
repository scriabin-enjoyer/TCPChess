# frozen_string_literal: true

require 'minitest/autorun'
require 'minitest/pride'
require_relative '../lib/protocol/main'

module ProtocolTests
  module ProtocolHelper
    include MyGameServer::Protocol

    module_function

    def random_bytes(n = 1)
      binstr = String.new(encoding: "BINARY")
      n.times { binstr << rand(0..255) }
      binstr
    end

    def generate_message_bytes(type: SYSTEM_T,
                               length: MIN_LENGTH_VALUE,
                               payload: [0])
      payload = payload.map { |byte| byte.chr.b }.join('')
      type.chr.b + length.chr.b + payload
    end

    def invalid_type_message
      invalid_type1 = 0xFE.chr.b
      invalid_type1 + 2.chr.b + 0.chr.b
    end

    def zerolength_field_message
      l = 0x00
      SYSTEM_T.chr.b + l.chr.b + l.chr.b
    end
  end
end
