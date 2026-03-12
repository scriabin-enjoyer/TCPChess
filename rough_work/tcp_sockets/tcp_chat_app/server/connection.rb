# frozen_string_literal: true

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
      @read_buffer = String.new
      @write_buffer = String.new
    end

    def to_io
      @socket
    end

    def monitor_for_reading?
      true
    end

    def monitor_for_writing?
      raise NotImplementedError
    end
  end
end
