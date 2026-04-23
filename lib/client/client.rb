require 'socket'
require_relative '../protocol/main.rb'

client = Socket.new(:INET, :STREAM)
addr = Socket.pack_sockaddr_in(2211, 'localhost')

client.connect addr

until (data = gets) == "\n"
  msg = MyGameServer::Protocol.generate_msg data.chomp
  p msg
  client.write msg
  sleep 1
  until (rx = client.read_nonblock(1024, exception: false)) == :wait_readable
    puts "RECEIVED: #{rx}"
  end
end

client.close
