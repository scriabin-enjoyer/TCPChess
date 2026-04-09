# frozen_string_literal: true

module MyGameServer
  module Protocol
    SYSTEM_T = 0xFF
    CHESS_T = 0x01

    # Reads in raw byte string
    def self.parse_tltv!(data)
      return if data.bytesize < 3

      t1, l, t2 = data.unpack("CC")
      return if data[3, l + 3].bytesize < l

      v = data.byteslice(3, l)
      { type1: t1, type2: t2, payload: v }
    end

    module System
      # echo req, reply
      # ping pong
      # bye
      # join game, queued, join success
      # game start
      # game end
      # game disconnect
      # Leave game
    end

    module Chess
    end
  end
end
