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

    def random_bytes_with_truncated_payload(n)
      type1 = rand(0..255).chr.b
      length = rand(1..255).chr.b
      type1 + length
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
