# frozen_string_literal: true

require_relative '../protocol/main'

module MyGameServer
  module Server
    class Connection
      def initialize(socket)
        @socket = socket.binmode
        @socket.setsockopt(:TCP, :NODELAY, true)
        @read_buffer = String.new(encoding: "BINARY")
        @write_event_queue = []
      end

      def monitor_for_reading?
        raise NotImplementedError
      end

      def monitor_for_writing?
        raise NotImplementedError
      end

      def on_connect
        raise NotImplementedError
      end

      def closed?
        raise NotImplementedError
      end

      def teardown
        raise NotImplementedError
      end

      def fileno
        raise NotImplementedError
      end

      def on_readable
        raise NotImplementedError
      end

      def on_writable
        raise NotImplementedError
      end
    end
  end
end
