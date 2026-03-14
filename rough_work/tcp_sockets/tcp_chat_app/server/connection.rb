# frozen_string_literal: true

require_relative '../message/message'

module TCPChatApp
  # Represents a connection between the Client and this Server
  # Wraps all Socket logic, connection handling, etc.
  # Manages all low-level socket input, output, and life-cycle
  # Acts as a protocol bridge as well, should handle streaming data from
  # transport layer and reconstructing full application-level messages,
  # especially when the message boundaries are not preserved with partial reads
  class Connection
    attr_reader :socket, :fd

    def initialize(socket)
      @socket = socket
      @fd = socket.fileno
      @message = Message
      @read_buffer = String.new
      @write_buffer = String.new
    end

    def disconnected?
      @socket.eof?
    end

    def close
      @socket.close
    end

    def to_io
      @socket
    end

    def on_readable
      raise NotImplementedError
    end

    def on_writable
      raise NotImplementedError
    end

    def monitor_for_reading?
      true
    end

    # NOTE: NOT IMPLEMENTED
    def monitor_for_writing?
      false
    end
  end
end
