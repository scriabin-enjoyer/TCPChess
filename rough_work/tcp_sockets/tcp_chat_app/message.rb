# frozen_string_literal: true

module TCPChatApp
  module Message
    # Message Types and Lengths (for fixed length messages)
    NOP_T = 0
    NOP_L = 0
    ECHO_REQ_T = 1
    ECHO_REQ_L = 6
    ECHO_REPLY_T = 2
    ECHO_REPLY_L = 6
    READY_T = 3
    MSG_T = 4
    MSG_RELAY_T = 5
    RECEIPT_T = 6
    RECEIPT_L = 1
    QUIT_T = 7
    QUIT_L = 0
    SHUTDOWN_T = 8
    SHUTDOWN_L = 0

    # Functions to generate message objects
    # We will just use arrays here for simplicity
    class Generator
      def nop
        [NOP_T, NOP_L]
      end

      def echo_req(timestamp: Time.now.utc.strftime("%H%M%S"))
        [ECHO_REQ_T, ECHO_REQ_L, timestamp]
      end

      def echo_reply(timestamp)
        [ECHO_REPLY_T, ECHO_REPLY_L, timestamp]
      end

      def ready(peer_name)
        [READY_T, peer_name.bytesize, peer_name]
      end

      def msg(message)
        [MSG_T, message.bytesize, message]
      end

      def msg_relay(message)
        [MSG_RELAY_T, message.bytesize, message]
      end

      def receipt(message_type)
        [RECEIPT_T, RECEIPT_L, message_type]
      end

      def quit
        [QUIT_T, QUIT_L]
      end

      def shutdown
        [SHUTDOWN_T, SHUTDOWN_L]
      end
    end

    # Functions to serialize message objects onto the wire
    class Serializer
    end

    # Functions to unpack and parse messages from the wire
    class Parser
    end
  end
end
