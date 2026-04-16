# frozen_string_literal: true

require_relative '../protocol_test_helper'

module ProtocolTests
  class ProtocolSpec < Minitest::Spec
    include ProtocolHelper
  end

  class TestProtocol < ProtocolSpec
    Protocol = MyGameServer::Protocol

    describe ".parse_tlv" do
      it "should return nil given less than min message byte size" do
        Protocol::MIN_MESSAGE_SIZE.times do |n|
          bdata = random_bytes(n)
          result = Protocol.parse_tlv(bdata)
          assert_nil result
        end
      end

      it "should return nil given truncated payload" do
        bdata = random_2bytes_with_valid_length_field
        result = Protocol.parse_tlv(bdata)
        assert_nil result
      end

      it "should raise ProtocolViolation if given invalid type" do
        bdata = invalid_type_message
        assert_raises(ProtocolError) { Protocol.parse_tlv(bdata) }
      end

      it "should raise ProtocolViolation if given invalid length field" do
        bdata = zerolength_field_message
        assert_raises(ProtocolViolation) { Protocol.parse_tlv(bdata) }
      end
    end
  end
end
