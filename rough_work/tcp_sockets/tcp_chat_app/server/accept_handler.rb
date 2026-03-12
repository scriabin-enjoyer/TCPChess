# frozen_string_literal: true

module TCPChatApp
  class AcceptHandler
    def initialize(connection_handler, room_factory: ChatRoom)
      @client_queue = []
      @room_factory = room_factory
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
        new_room = @room_factory.new(client_a, client_b)
        @connection_handler.receive(new_room)
      end
    end
  end
end
