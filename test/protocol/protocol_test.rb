# frozen_string_literal: true

require_relative '../protocol_test_helper'

module ProtocolTests
  class ProtocolSpec < Minitest::Spec
    include ProtocolHelper
  end

  class TestProtocol < ProtocolSpec
    Protocol = MyGameServer::Protocol

    describe ".parse_tlv" do
      # Insufficient message length

      it "should return nil given less than min message byte size" do
        Protocol::MIN_MESSAGE_SIZE.times do |n|
          bdata = Random.bytes(n)
          result = Protocol.parse_tlv(bdata)
          assert_nil result
        end
      end

      it "should return nil given truncated payload" do
        bdata = truncated_payload
        result = Protocol.parse_tlv(bdata)
        assert_nil result
      end

      # Protocol violations

      it "should raise ProtocolViolation if given invalid type" do
        bdata = invalid_type_message
        assert_raises(ProtocolViolation) { Protocol.parse_tlv(bdata) }
      end

      it "should raise ProtocolViolation if given invalid length field" do
        bdata = invalid_length_message
        assert_raises(ProtocolViolation) { Protocol.parse_tlv(bdata) }
      end

      it "should raise ProtocolViolation if length field does not match payload size" do
        msg_data = { type1: 1, length: 10, payload: "\x0".b * 11 }
        assert_raises(ProtocolViolation) { Protocol::Event.new(**msg_data) }
      end

      # Valid data

      it "should parse and return a Protocol::Event object with correct fields" do
        bdata = generate_message_bytes
        result = Protocol.parse_tlv(bdata)
        assert result.is_a? Protocol::Event
        assert result.type1 == 255
        assert result.length == 1
        assert result.payload == "\x00".b
        assert result.bytesize == 3
      end

      it "should return the proper number of bytes read" do
        bdata = generate_message_bytes(length: 10, payload: [1] * 10)
        result = Protocol.parse_tlv(bdata)
        assert result.bytesize == bdata.length
      end

      it "should parse full SYSTEM_T message properly" do
        bdata = generate_message_bytes
        result = Protocol.parse_tlv bdata
        assert result.type1 == SYSTEM_T
      end

      it "should parse full CHESS_T message properly" do
        bdata = generate_message_bytes(type1: CHESS_T)
        result = Protocol.parse_tlv bdata
        assert result.type1 == CHESS_T
      end
    end
  end
end
