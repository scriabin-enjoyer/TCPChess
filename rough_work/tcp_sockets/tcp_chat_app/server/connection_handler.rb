# frozen_string_literal: true

module TCPChatApp
  class ConnectionHandler
    def initialize
      raise NotImplementedError
    end

    # Delegate action based on readable connection
    # Dispatched from Server
    def process_readable(connection)
      raise NotImplementedError
    end

    # Receive new ChatRoom instance from AcceptHandler
    def receive(new_chat_room)
      raise NotImplementedError
    end
  end
end
