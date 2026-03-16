# frozen_string_literal: true

module TCPChatAppServer
  # Consists of 2 clients
  # Responsible for handling all state and communication between 2 connected
  # clients
  class ChatRoom
    def initialize(client1, client2)
      @client1 = client1
      @client2 = client2
    end
  end
end
