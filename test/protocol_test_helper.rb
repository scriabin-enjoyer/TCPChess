# frozen_string_literal: true

require 'minitest/autorun'
require 'minitest/pride'
require_relative '../lib/protocol/main'

module ProtocolTests
  module ProtocolHelper
    include MyGameServer::Protocol

    module_function

    # Default: generates "\xFF\x1\x0"
    def generate_message_bytes(type1: SYSTEM_T,
                               length: MIN_LENGTH_VALUE,
                               payload: [0])
      payload = payload.map { |byte| byte.chr.b }.join('')
      type1.chr.b + length.chr.b + payload
    end

    # valid type1, valid length, payload length < length value
    def truncated_payload
      generate_message_bytes length: 10, payload: [0] * 5
    end

    # invalid type1, valid length, payload with length bytes
    def invalid_type_message
      invalid_type1 = (0..255).reject { it == SYSTEM_T || it == CHESS_T }.sample
      generate_message_bytes type1: invalid_type1
    end

    # valid type1, 0 length, 0 payload
    def invalid_length_message
      generate_message_bytes length: 0
    end
  end
end
