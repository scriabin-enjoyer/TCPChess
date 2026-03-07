# frozen_string_literal: true

module TCPChatApp
  # Contains message formats for a nice chat interface for the user
  class UI
    def initialize(user, output = $stdout)
      @user = user
      @peer = nil
      @output = output
    end

    def welcome
      @output.puts <<~WELCOME
      Welcome! You have been assigned id #{@user}. Currently trying to connect to server. Type 'exit' to quit at any time.
      WELCOME
    end

    def puts_connect_success
      @output.puts "Successfully connected to central chat server. Looking for a peer for you to chat with..."
    end

    def set_peer(peer)
      @peer = peer
    end

    def bye
      @output.puts "Thanks for chatting. See you, Space Cowboy."
    end

    def write_sent(message)
      @output.puts("#{@user}(ME)>>> #{message}")
    end

    def write_received(message)
      @output.puts("#{@peer}(PEER)<<< #{message}")
    end
  end
end
