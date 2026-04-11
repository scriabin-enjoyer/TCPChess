# frozen_string_literal: true

module MyGameServer
  module Protocol
    # Implements the SYSTEM-type protocol messages
    module System
      class SystemError < ProtocolError; end

      SYSTEM_T = 0xFF
      ECHO_REQ_T = 0x01
      ECHO_REPLY_T = 0x02
      PING_T = 0x03
      PONG_T = 0x04
      BYE_T = 0x05
      JOIN_GAME_T = 0x06
      QUEUED_T = 0x07
      JOIN_SUCCESS_T = 0x08
      GAME_START_T = 0x09
      GAME_END_T = 0x0A
      GAME_DISCONNECT_T = 0x0B
      LEAVE_GAME_T = 0x0C
      ACK_T = 0x0D
      INFO_T = 0x0E
      ERROR_T = 0x0F

      # Parsing: Event structure
      # {
      #   :msg_len => total length of message,
      #   :message => {
      #     :type => top level type,
      #     :length => length field,
      #     :payload => binary string, (type2, value)
      #   }
      # }
      #
      # Protocol.parse_tlv validates Type1 field and Length field
      def self.parse(msg)
        raise NotImplementedError
        # Check that top-level type is valid (0xFF)
        #
      end

      # echo req, reply
      # ping pong
      # bye
      # join game, queued, join success
      # game start
      # game end
      # game disconnect
      # Leave game
    end
  end
end
