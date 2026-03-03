# frozen_string_literal: true

module TCPChatApp
  class Client
    REMOTE_PORT = 2211
    REMOTE_HOST = 'localhost'

    def initialize
      @id = Time.now.hash.to_s(16)[0..6]
      @ui = UI.new(@id)
      @ui.welcome
      # Just let it fail for now if the connect is unsuccessful
      @server = TCPSocket.new(REMOTE_HOST, REMOTE_PORT, connect_timeout: 60)
      @ui.puts_connect_success
    end

    def loop
      # send message to server indicating we are looking to get matched with a peer
      # print "connected to peer" message if successfully matched, print server error otherwise

    end
  end
end

