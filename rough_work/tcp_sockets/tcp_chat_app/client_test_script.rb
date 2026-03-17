# frozen_string_literal: true

require 'socket'

class ClientTest
  def initialize
    @client = nil

    trap(:INT) do
      @client.&close
      exit
    end
  end

  def run
    loop do
      @client = TCPSocket.new('localhost', 2211)
      while (data = gets.chomp)
        break if data == 'reset'

        puts "Sending data..."
        @client.write(data)
      end
    end
  end
end

ClientTest.new.run
