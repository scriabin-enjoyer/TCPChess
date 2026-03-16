# frozen_string_literal: true

require_relative '../message/message'

module TCPChatApp
  # Represents a connection between the Client and this Server
  # Wraps all Socket logic, connection handling, etc.
  # Manages all low-level socket input, output, and life-cycle
  # Acts as a protocol bridge as well, should handle streaming data from
  # transport layer and reconstructing full application-level messages,
  # especially when the message boundaries are not preserved with partial reads
  #
  # Connection/Server:
  #   - on_readable, on_writable,
  class Connection
    attr_reader :socket, :fd

    def initialize(socket)
      @socket = socket
      @fd = socket.fileno
      @event_handler = EventHandler.new
      @message = Message
      @read_buffer = String.new
      @write_buffer = String.new
      @write_event_queue = []
    end

    def to_io
      @socket
    end

    # METHODS FOR READING/WRITING:

    # Stream out binary data from socket
    # Emit event objects
    def on_readable
      raise NotImplementedError
    end

    # Flush event queue
    def on_writable
      raise NotImplementedError
      @socket.write_nonblock(@write_buffer)
      @write_buffer.clear
    end

    # METHODS FOR PARSING:
    # METHODS FOR EMITTING EVENTS:
    # METHODS FOR MANAGING SOCKET LIFECYCLE
    def close
      @socket.close
    end

    # METHODS FOR QUERYING STATE
    def state
      @state
    end

    def closed?
      @socket.closed?
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
