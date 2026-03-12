# frozen_string_literal: true

module TCPChatApp
  module Message
    # Message Types and Lengths/Pack Directives (for fixed length messages)

    # No Op (Fixed Length)
    NOP_T = 0
    NOP_L = 0
    NOP_P = "CC"
    # Echo Request (Fixed Length)
    ECHO_REQ_T = 1
    ECHO_REQ_L = 6
    ECHO_REQ_P = "CCA6"
    # Echo Reply (Fixed Length)
    ECHO_REPLY_T = 2
    ECHO_REPLY_L = 6
    ECHO_REPLY_P = "CCA6"
    # Ready (Variable Length)
    READY_T = 3
    # Message (Variable Length)
    MSG_T = 4
    # Message Relay (Variable Length)
    MSG_RELAY_T = 5
    # Receipt (Fixed Length)
    RECEIPT_T = 6
    RECEIPT_L = 1
    RECEIPT_P = "CCC"
    # Quit (Fixed Length)
    QUIT_T = 7
    QUIT_L = 0
    QUIT_P = "CC"
    # Shutdown (Fixed Length)
    SHUTDOWN_T = 8
    SHUTDOWN_L = 0
    SHUTDOWN_P = "CC"

    def self.generate_serial(type, msg_data: nil)
      raise NotImplementedError
    end

    def self.parse(msg)
      raise NotImplementedError
    end

    # Generates serialized messages to send over the wire
    module Generator
      module_function

      def nop
        [NOP_T, NOP_L].pack(NOP_P)
      end

      def echo_req(timestamp: Time.now.utc.strftime("%H%M%S"))
        [ECHO_REQ_T, ECHO_REQ_L, timestamp].pack(ECHO_REQ_P)
      end

      def echo_reply(timestamp)
        [ECHO_REPLY_T, ECHO_REPLY_L, timestamp].pack(ECHO_REPLY_P)
      end

      def ready(peer_name)
        # NOTE: Remember to handle bounds!
        peer_name_len = peer_name.bytesize
        [READY_T, peer_name_len, peer_name].pack("CCA#{peer_name_len}")
      end

      def msg(message)
        # NOTE: Remember to handle bounds!
        msg_len = message.bytesize
        [MSG_T, msg_len, message].pack("CCA#{msg_len}")
      end

      def msg_relay(message)
        # NOTE: Remember to handle bounds!
        msg_len = message.bytesize
        [MSG_RELAY_T, msg_len, message].pack("CCA#{msg_len}")
      end

      def receipt(message_type)
        [RECEIPT_T, RECEIPT_L, message_type].pack(RECEIPT_P)
      end

      def quit
        [QUIT_T, QUIT_L].pack(QUIT_P)
      end

      def shutdown
        [SHUTDOWN_T, SHUTDOWN_L].pack(SHUTDOWN_P)
      end
    end

    # Functions to unpack and parse messages from the wire. This should emit
    # application-level messages. Data that is passed to the methods in this
    # module should consist of complete and validated binary strings that
    # constitute legal app-level messages, formatted according to our protocol.
    # We should still validate here regardless.
    module Parser
      class ParserError < StandardError; end

      class << self
        def nop(data)
          t, l = data.unpack(NOP_P)
          {
            type: t,
            length: l
          }
        end

        def echo_req(data)
          t, l, v = data.unpack(ECHO_REQ_P)
          v.force_encoding(Encoding::ASCII_8BIT)
          {
            type: t,
            length: l,
            value: v
          }
        end

        def echo_reply(data)
          t, l, v = data.unpack(ECHO_REPLY_P)
          v.force_encoding(Encoding::ASCII_8BIT)
          {
            type: t,
            length: l,
            value: v
          }
        end

        def ready(data)
          t = data.getbyte(0)
          l = data.getbyte(1)
          v = data.byteslice(2, l).force_encoding(Encoding::UTF_8)
          {
            type: t,
            length: l,
            value: v
          }
        end

        def msg(data)
          t = data.getbyte(0)
          l = data.getbyte(1)
          v = data.byteslice(2, l).force_encoding(Encoding::UTF_8)
          {
            type: t,
            length: l,
            value: v
          }
        end

        def msg_relay(data)
          t = data.getbyte(0)
          l = data.getbyte(1)
          v = data.byteslice(2, l).force_encoding(Encoding::UTF_8)
          {
            type: t,
            length: l,
            value: v
          }
        end

        def receipt(data)
          t, l, v = data.unpack(RECEIPT_P)
          {
            type: t,
            length: l,
            value: v
          }
        end

        def quit(data)
          t, l = data.unpack(QUIT_P)
          {
            type: t,
            length: l
          }
        end

        def shutdown(data)
          t, l = data.unpack(SHUTDOWN_P)
          {
            type: t,
            length: l
          }
        end

        private

        def validate(meth)
        end
      end
    end
  end
end
