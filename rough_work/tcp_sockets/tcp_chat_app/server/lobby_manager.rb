# frozen_string_literal: true

require_relative 'chat_room'

module TCPChatAppServer
  class LobbyManager
    def initialize(room_manager_instance, room_factory)
      @room_factory = room_factory
      @room_manager = room_manager_instance
      @lobby_queue = []
      @chat_room_queue = []
    end

    # 1. receives events from the EventHandler
    def receive_client(event)
      raise NotImplementedError
    end

    # 2. match clients in a queue if they can be matched
    def on_new_client
      raise NotImplementedError
    end

    # flushes lobby_queue into chat_room_queue
    def flush_lobby
      raise NotImplementedError
    end

    # 3. Perform Echo Exchange
    def echo_exchange
      raise NotImplementedError
    end

    # 4. Hand off ChatRooms to the RoomManager
    def flush_rooms
      raise NotImplementedError
    end
  end
end
