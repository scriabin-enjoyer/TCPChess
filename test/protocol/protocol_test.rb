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
          bdata = random_bytes(n)
          result = Protocol.parse_tlv(bdata)
          assert_nil result
        end
      end

      it "should return nil given truncated payload" do
        bdata = generate_message_bytes(length: 3, payload: [1])
        result = Protocol.parse_tlv(bdata)
        assert_nil result
      end

      # Protocol violations

      it "should raise ProtocolViolation if given invalid type" do
        bdata = invalid_type_message
        assert_raises(ProtocolViolation) { Protocol.parse_tlv(bdata) }
      end

      it "should raise ProtocolViolation if given invalid length field" do
        bdata = zerolength_field_message
        assert_raises(ProtocolViolation) { Protocol.parse_tlv(bdata) }
      end

      # Valid data

      it "should parse and return an array with the proper structure" do
        bdata = generate_message_bytes
        result = Protocol.parse_tlv(bdata)
        assert result.is_a? Array
        assert result.length == 2
        assert result.first.is_a? Protocol::Event
        assert result.last.is_a? Integer
      end

      it "should return the proper number of bytes read" do
        bdata = generate_message_bytes(length: 10, payload: [1] * 10)
        result = Protocol.parse_tlv(bdata)
        assert result.last == bdata.length
      end

      it "should parse full SYSTEM_T message properly" do
        bdata = generate_message_bytes
        result = Protocol.parse_tlv bdata
        assert result.first.type1 == SYSTEM_T
      end

      it "should parse full CHESS_T message properly" do
        bdata = generate_message_bytes(type: CHESS_T)
        result = Protocol.parse_tlv bdata
        assert result.first.type1 == CHESS_T
      end
    end

    describe ".serialize_tlv" do
      it "should work" do
        skip
      end
    end
  end
end
