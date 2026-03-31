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
  # on_readable, on_writable, on_connect, closed?, fileno, monitor_for_rw?, to_io
  #
  # Connection/EventHandler interface:
  class Connection
    attr_reader :socket

    def initialize(socket, event_handler_instance)
      @socket = socket
      @fd = socket.fileno
      @parser = Parser.new
      @event_handler = event_handler_instance
      @event_read_queue = []
    end

    def fileno
      @fd
    end

    def to_io
      @socket
    end

    # Stream out binary data from socket
    def on_connect
      raise NotImplementedError
    end

    # Emit event objects:
    # Read all data from socket into a buffer
    # Parse and emit as many events to the EventHandler as possible
    def on_readable
      raise NotImplementedError
      @parser.consume(@socket)
    end

    # Flush event queue
    def on_writable
      raise NotImplementedError
      @socket.write_nonblock(@write_buffer)
      @write_buffer.clear
    end

    def close
      @socket.close
    end

    def closed?
      @socket.closed?
    end

    def monitor_for_reading?
      true
    end

    def monitor_for_writing?
      false
    end
  end
end

# A stateful TLV Parser. Implements a finite state machine. The following
# interface should receive data from TCP (via TCP sockets), parse it, and
# emit as many fully-formed application level events as possible.
# Incomplete messages and offsets should be stored for use later, when more
# data is available to read.
class Parser
  # states:
  STATE = {
    type: 0,
    length: 1,
    value: 2
  }

  def initialize
    @read_buffer = String.new
    @offset = 0
    @type = nil
    @length = nil
    @value = nil
    @bytes_to_read = 0
  end

  def emit_messages
    parse until @state == :waiting_on_data
  end

  def parse
    case @read_buffer[@offset]
    when false
    else
    end
  end

  def <<(bin_data)
    @read_buffer << bin_data
  end

  def try_parse
    raise NotImplementedError
  end
end
