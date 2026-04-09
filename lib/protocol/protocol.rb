# frozen_string_literal: true

module MyGameServer
  # Namespace for all Protocol related features. Game applications that want
  # to add a game to the Server should implement their protocol in this
  # module (message generators, parsers) in their own class/module, and
  # register their top-level type as a constant in this file, at the top of
  # this module.
  module Protocol
    # Register types here
    SYSTEM_T = 0xFF
    CHESS_T = 0x01

    # Useful constants
    MIN_MSG_LEN = 3

    # Custom exceptions
    class ProtocolError < StandardError; end
    class BadHeader < ProtocolError; end

    module_function

    # Reads in raw byte string returns hash containing top level type,
    # corresponding op-code, and the raw binary payload if it exists. Returns
    # nil if there is not enough structured data to emit a full protocol
    # message.
    def parse_tltv!(data)
      return if data.bytesize < 3

      t1, l, t2 = data.unpack("CCC")
      raise BadHeader, "0 length message" if l == 0
      raise BadHeader, "Received Invalid Protocol ID #{t1}" unless valid_protocol?(t1)

      v = data.byteslice(2, l)
      return unless v && v.bytesize == l

      # Don't unpack the payload here since it will require specific
      # interpretation at a higher level
      { type1: t1, type2: t2, payload: v }
    end

    def valid_protocol?(type)
      type == SYSTEM_T || type == CHESS_T
    end
  end
end
