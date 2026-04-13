# frozen_string_literal: true

module MyGameServer
  module Protocol
    # Implements the SYSTEM-type protocol messages
    module System
      class SystemProtocolError < ProtocolError; end

      # ECHO_REQUEST (Fixed)
      ECHO_REQ_L = 0x0D
      ECHO_REQ_T = 0x01
      ECHO_REQ_H = (SYSTEM_T.chr + ECHO_REQ_L.chr + ECHO_REQ_T.chr).b.freeze
      # ECHO_REPLY (Fixed)
      ECHO_REPLY_L = 0x0D
      ECHO_REPLY_T = 0x02
      ECHO_REPLY_H = (SYSTEM_T.chr + ECHO_REPLY_L.chr + ECHO_REPLY_T.chr).b.freeze
      # PING (fixed)
      PING_L = 0x01
      PING_T = 0x03
      PING_H = (SYSTEM_T.chr + PING_L.chr + PING_T.chr).b.freeze
      # PONG (fixed)
      PONG_L = 0x01
      PONG_T = 0x04
      PONG_H = (SYSTEM_T.chr + PONG_L.chr + PONG_T.chr).b.freeze
      # BYE (variable length)
      BYE_T = 0x05
      # JOIN_GAME (fixed)
      JOIN_GAME_L = 0x02
      JOIN_GAME_T = 0x06
      JOIN_GAME_H = (SYSTEM_T.chr + JOIN_GAME_L.chr + JOIN_GAME_T.chr).b.freeze
      # QUEUED (fixed)
      QUEUED_L = 0x02
      QUEUED_T = 0x07
      QUEUED_H = (SYSTEM_T.chr + QUEUED_L.chr + QUEUED_T.chr).b.freeze
      # JOIN_SUCCESS (fixed)
      JOIN_SUCCESS_L = 0x02
      JOIN_SUCCESS_T = 0x08
      JOIN_SUCCESS_H = (SYSTEM_T.chr + JOIN_SUCCESS_L.chr + JOIN_SUCCESS_T.chr).b.freeze
      # GAME_START (fixed)
      GAME_START_L = 0x02
      GAME_START_T = 0x09
      GAME_START_H = (SYSTEM_T.chr + GAME_START_L.chr + GAME_START_T.chr).b.freeze
      # GAME_END (fixed)
      GAME_END_L = 0x02
      GAME_END_T = 0x0A
      GAME_END_H = (SYSTEM_T.chr + GAME_END_L.chr + GAME_END_T.chr).b.freeze
      # GAME_DISCONNECT (fixed)
      GAME_DISCONNECT_L = 0x02
      GAME_DISCONNECT_T = 0x0B
      GAME_DISCONNECT_H = (SYSTEM_T.chr + GAME_DISCONNECT_L.chr + GAME_DISCONNECT_T.chr).b.freeze
      # LEAVE_GAME (fixed)
      LEAVE_GAME_L = 0x02
      LEAVE_GAME_T = 0x0C
      LEAVE_GAME_H = (SYSTEM_T.chr + LEAVE_GAME_L.chr + LEAVE_GAME_T.chr).b.freeze
      # ACK (fixed)
      ACK_L = 0x02
      ACK_T = 0x0D
      ACK_H = (SYSTEM_T.chr + ACK_L.chr + ACK_T.chr).b.freeze
      # INFO (variable length)
      INFO_T = 0x0E
      # ERROR (fixed)
      ERROR_L = 0x02
      ERROR_T = 0x0F
      ERROR_H = (SYSTEM_T.chr + ERROR_L.chr + ERROR_T.chr).b.freeze

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
