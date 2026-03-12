# frozen_string_literal: true

module TCPChatApp
  class ConnectionHandler
    def initialize
      raise NotImplementedError
    end

    def process_readable(connection)
      raise NotImplementedError
    end
  end
end
