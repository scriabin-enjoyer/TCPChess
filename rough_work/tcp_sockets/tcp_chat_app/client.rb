# frozen_string_literal: true

module TCPChatApp
  # Clients can:
  # - register with the server
  # - send a broadcast message to the server
  # - request a list of active clients
  # - send a message to a specific client
  # Protocol: Basic TLV
  #   - Header: 2 bytes. First byte is a MSG_TYPE defined above. Second is a
  #   Length -- ranges from 0 to 255
  #   - Payload:
  class Client
    # seconds
    TIMEOUT = 5

    def initialize(id)
      @id = id
      @socket = Socket.new :INET, :STREAM
      @remote_addr = Socket.pack_sockaddr_in(REMOTE_PORT, 'localhost')
    end

    def connect_to_server
      conn_status = @socket.connect_nonblock(@remote_addr, exception: false)
      IO.select(nil, [@socket], nil, TIMEOUT) if conn_status == :wait_writable

      conn = @socket.connect_nonblock(@remote_addr, exception: false)
    end
  end
end

