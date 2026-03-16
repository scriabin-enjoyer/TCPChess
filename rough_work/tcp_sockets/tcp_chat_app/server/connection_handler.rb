# frozen_string_literal: true

module TCPChatAppServer
  class ConnectionHandler
    def initialize
      @room_manager = []
      @new_rooms = []
    end

    # Delegate action based on readable connection
    # Dispatched from Server
    def process_readable(connection)
      log :note, "Processing Readables"

      loop do
        data = connection.socket.read_nonblock(100, exception: false)
        break if data == :wait_readable

        if data == nil
          connection.close
          puts "EOF"
          return
        end

        puts data
      end
    end

    # Receive new ChatRoom instance from AcceptHandler
    def receive(new_chat_room)
      @new_rooms << new_chat_room
    end

    # echo handshake, ready messages
    def process_new_chatrooms
      raise NotImplementedError
    end
  end
end
