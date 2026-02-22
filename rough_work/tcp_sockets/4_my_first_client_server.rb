# frozen_string_literal: true

# rubocop:disable Lint/MissingCopEnableDirective
# rubocop:disable Lint/RedundantCopDisableDirective
# rubocop:disable Lint/UselessAssignment
# rubocop:disable Metrics/MethodLength
# rubocop:disable Metrics/ClassLength
# rubocop:disable Naming/MethodParameterName
# rubocop:disable Naming/AccessorMethodName

# First Server:
# NOTES:
#   - If a new client connection arrives and the listen queue is full then the
#   client will raise Errno::ECONNREFUSED
#   - Socket::SOMAXCONN is 4096 on this machine.
#   - Normal Socket#accept blocks
class FirstServer
  PORT = 2211
  ADDR = '0.0.0.0'
  BACKLOG_SIZE = 100
  MSG_SEPARATOR = "\r\n\r\n"

  def initialize
    @listening_socket = Socket.new(:INET, :STREAM)
    @local_addr = Socket.pack_sockaddr_in(PORT, ADDR)
    @listening_socket.bind(@local_addr)
    @listening_socket.listen(BACKLOG_SIZE)
    @clients = []
  end

  def start
    loop do
      process_client_sockets
      client, = @listening_socket.accept_nonblock
      client.sync = true
      @clients << client
    end
  rescue IO::WaitReadable
    sleep 0.5
    retry
  ensure
    @clients.each &:close
  end

  def process_client_sockets
    @clients.each do |client|
      @msg_queue << client.gets
    end
  end

  def queue_messages
    Thread.new do
      loop do
        @msg_queue.push ''
      end
    end
  end

  def broadcast_messages
    Thread.new do
      loop do
        print_message(@msg_queue.pop)
      end
    end
  end
end

# Connects to server; writes messages onto socket
class FirstClient
  REMOTE_ADDR = 'localhost'
  REMOTE_PORT = 2211
  MSG_SEPARATOR = "\r\n\r\n"

  def initialize
    @local_socket = Socket.new(:INET, :STREAM)
    @local_socket.sync = true
    @server_addr = Socket.pack_sockaddr_in(REMOTE_ADDR, HOST_PORT)
  end

  def connect_to_server
    @local_socket.connect @server_addr
  end

  def write(msg)
    @local_socket.write(msg + MSG_SEPARATOR)
  end
end
