# frozen_string_literal: true

require_relative 'chat_room'

module TCPChatAppServer
  class AcceptHandler
    def initialize(connection_handler)
      @client_queue = []
      @connection_handler = connection_handler
    end

    def intake(client)
      @client_queue << client
      process_queue
    end

    def process_queue
      while @client_queue.size >= 2
        client_a = @client_queue.shift
        client_b = @client_queue.shift
        new_room = ChatRoom.new(client_a, client_b)
        @connection_handler.receive(new_room)
      end
    end
  end
end
