# frozen_string_literal: true

require_relative '../protocol_test_helper'

class TestProtocol < Minitest::Test
  include ProtocolHelper

  Protocol = MyGameServer::Protocol

  # generate good data:
  #   - >= min message size
  #   - valid type, length
  #   - sufficient byte size to parse
  #   - good return values:
  #     - array if correct and large enough data
  #     - nil if not enough data
  #     - nil if not enough data to parse full message
  #
  # generate bad data:
  #   - insufficient data size
  # Small Messages
  def test_returns_nil_on_1byte_message
    bdata = generate_byte
    result = Protocol.parse_tlv(bdata)
    assert_nil result
  end

  def test_returns_on_insufficient_length
    bdata = generate_2bytes
    result = Protocol.parse_tlv(bdata)
    assert_nil result
  end

  def test_invalid_type_field
  end

  def test_invalid_length_field
  end
end
