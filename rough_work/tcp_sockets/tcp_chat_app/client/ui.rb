# frozen_string_literal: true

module TCPChatApp
  # Contains message formats for a nice chat interface for the user
  class UI
    def initialize(output = $stdout)
      print 'Enter your nickname: '
      @user = gets.chomp
      @peer = nil
      @output = output
    end

    def welcome
      @output.puts <<~WELCOME
      Welcome #{@user}! Currently trying to connect to server. Type 'exit' to quit at any time.
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
      @output.puts("#{@user}>>> #{message}")
    end

    def write_received(message)
      @output.puts("#{@peer}<<< #{message}")
    end
  end
end
