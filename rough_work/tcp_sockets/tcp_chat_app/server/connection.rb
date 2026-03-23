# frozen_string_literal: true

require_relative '../message/message'

module TCPChatAppServer
  # (Application-level) Events are specified by the pair (conn, event), where
  # conn is a particular connection object and event is a hash that specifies a
  # protocol-level message
  #
  # Connection itself consists of several layers:
  #
  # Connection/EventHandler interface: 
  #
  # Connection::EventEmitter layer
  # Connection::StateManagement layer
  # Connection::Parsing layer
  #
  # Connection/Server interface
  #
  # Connection/Server interface is unidirectional — the Server has a reference
  # to Connection, but Connection knows nothing about the Server.
  #
  # The Server uses this subset of the interface defined in this class:
  # on_readable, on_writable, on_connect, closed?, fileno, monitor_for_rw?
  #
  # Connection/EventHandler interface:
  class Connection
    attr_reader :socket

    def initialize(socket, event_handler_instance)
      @socket = socket
      @fd = socket.fileno
      @event_handler = event_handler_instance
      @message = Message
      @read_buffer = String.new
      @write_buffer = String.new
      @write_event_queue = []
    end

    def fileno
      @fd
    end

    def to_io
      @socket
    end

    # METHODS FOR READING/WRITING:

    # Stream out binary data from socket
    def on_connect
      puts "OH YEAH BABY"
    end

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
