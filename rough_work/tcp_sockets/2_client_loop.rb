# frozen_string_literal: true

require 'socket'

# Client Lifecycle:
# 1. Create
# 2. Bind
# 3. Connect
# 4. Close

# Clients initiate connections with the Server. They know (via DNS for example)
# the location of a particular server and create an outbound connection to it.
# Step 1. above is the same as the Create step in the Server lifecycle

# We don't actually Bind the client to a (address, port)
module ClientsBind
  # While Servers usually always bind, Clients rarely make a call to bind
  # The reason for this is that, if a client socket omits its call to bind,
  # then it will be assigned a random port number from the ephemeral range.
  # The recommendation is then: Don't call bind
end

# Instead, we can use Socket#connect
module ClientsConnectSuccessfully
  # Apparently, google doesn't like IPv4 here
  socket = Socket.new :INET6, :STREAM
  # Initiate a connection to google.com on port 80
  remote_addr = Socket.pack_sockaddr_in(80, 'google.com')
  if ARGV.include? 'connect-to-google'
    socket.connect(remote_addr)
    socket.write("GET / HTTP/1.0\r\n\r\n")
    results = socket.read
    puts results
  end
end

# Sometimes, it is possible for a client socket to connect to a server before
# it is ready to accept a new connection, or for the client to connect to a
# non-existent server. TCP is optimistic, meaning it will wait as long as it
# can for a response from a remote host.
module ClientsConnectTimeout
  # This raises an Errno::EACCES error - permission denied. I guess google just
  # refuses to connect on this port. The gopher protocol (corresponding to port
  # 70 I guess) is a bit of a precursor to HTTP, made in the 1970s, but is
  # basically forgotten. Apparently there are some gopher servers still in use
  # today.
  if false
    socket = Socket.new(:INET6, :STREAM)
    # Attempt to connect to google.com on the known gopher port.
    remote_addr = Socket.pack_sockaddr_in(70, 'google.com')
    socket.connect(remote_addr)
  end

  # The idea is that the above (TCP) client socket will try to wait for as long
  # as possible before our OS decides that too much time has passed and raises
  # a Timeout error.
end

# Abstractions Over Client Sockets
module ClientConstruction
  if false
    # Behold, the sugar:
    socket = TCPSocket.new('google.com', 80)

    # And even more:
    Socket.tcp('google.com', 80) do |connection|
      connection.write "GET / HTTP/1.1\r\n"
      connection.close
    end

    # Omitting the block argument behaves the same
    # as TCPSocket.new().
    client = Socket.tcp('google.com', 80)
  end
end
