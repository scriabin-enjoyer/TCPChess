# From the "Working With TCP Sockets" ebook, the Timeouts section:
#
# "Your operating system also offers native socket timeouts that can be set via
# the SNDTIMEO and RCVTIMEO socket options. But, as of Ruby 1.9, this feature
# is no longer functional. Due to the way that Ruby handles blocking IO in the
# presence of threads, it wraps all socket operations around a poll(2), which
# mitigates the effect of the native socket timeouts. So those are unusable
# too."
#
# In order to test this, we can write a little script (below) and look at the
# syscalls this program invokes using strace:
#
# strace -e poll,ppoll,select,accept,connect,open ruby ruby_poll_test.rb 

require 'socket'

puts "\n\nINITIALIZING: server_addr\n\n"
server_addr = Socket.pack_sockaddr_in(2211, '0.0.0.0')

# Create a server and a client
puts "\n\nINITIALIZING: server socket\n\n"
server = Socket.new(:INET, :STREAM).then do |socket|
  socket.bind server_addr
  socket.listen(10)
  socket
end

puts "\n\nINITIALIZING: client socket\n\n"
client = Socket.new(:INET, :STREAM).then do |socket|
  socket.connect(server_addr)
  socket
end

puts "\n\nINITIALIZING: accept call\n\n"
peer, = server.accept

puts "\n\nSERVER FD: #{server.fileno}"
puts "CLIENT FD: #{client.fileno}"
puts "PEER FD: #{peer.fileno}"
puts "Executing blocking read...\n\n"

peer.read(10)
