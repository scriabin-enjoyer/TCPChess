# frozen_string_literal: true

# rubocop:disable Style/StringLiterals

require 'socket'

# The Berkeley Socket interface is the standard programming interface for
# virtually all application level software. The code in this module
# demonstrates how to use them, however Ruby does provide some abstractions on
# top of the Socket library, like TCPSocket, TCPServer, UnixServer, etc.
module Sockets
  # A socket creates a bidrectional endpoint for communication and returns a
  # file descriptor that refers to that endpoint. It is defined uniquely by 3
  # things:
  # - Domain: specifies a communication domain, which represents a family of
  # protocols that may be used for communication
  # - Type: specifies the communication semantics, primarily Streams and
  # Datagrams
  # - Protocol: specifies a particular protocol to be used with the
  # corresponding Domain and Type. Sometimes, a specified Domain and Type imply
  # that only a single Protocol may be used, and other times there may be
  # several Protocols or Protocol variants that may be used in which case we
  # need to specify the Protocol.

  # Importantly, not all combinations of (domain, type, protocol) are valid and
  # invalid combinations will be rejected. The interface was designed in such a
  # way that this triple may be used to specify arbitrary communication
  # protocol stacks. For instance:
  #   - (AF_INET, SOCK_STREAM, IPPROTO_TCP) encodes TCP connection over IPv4
  #   - (AF_PACKET, SOCK_RAW, ETH_P_IP) encodes an Ethernet connection
  #   transporting IP packets! ETH_P_IP on my machine is 0x800, see
  #   /usr/include/linux/if_ether.h for various protocol variants available on
  #   your machine

  # Here we create a Socket object with the IPv4 (INET) address family with a
  # Stream type. The Protocol argument is optional, and defaults to 0 if not
  # given, specifying the default protocol for the give Domain and Type:
  Socket.new(Socket::AF_INET, Socket::SOCK_STREAM)
end

# Server Lifecycle:
# 1. Create
# 2. Bind
# 3. Listen
# 4. Accept
# 5. Close
module ServerLifcycle
  # Ruby — ever the sweetest language:
  server = Socket.new(:INET, :STREAM)

  # We Bind a Socket instance to a local (address, port) combination. The
  # address specifies an (IP) address that is local to this machine, i.e.
  # "belongs" to this machine assigned via (probably) DHCP between this machine
  # and its default gateway (or something). The port number specifies further
  # which process on this machine is responsible for any data that is
  # sent/received by this socket. So the "address" identifies this machine or
  # a specific (physical) network interface that this machine has, and the port
  # number specifies the process on this machine that is connected to the
  # socket. This following code packs its arguments into a properly formatted
  # struct that bind(2) is supposed to receive, and the address '0.0.0.0'
  # matches against all addresses that this machine has, including the loopback
  # address:
  addr = Socket.pack_sockaddr_in(4481, '0.0.0.0')
  server.bind(addr)

  # Now, no other socket will be able to bind to port 4481 because the above
  # addr is matched against all local addresses. This is apparently what a lot
  # of servers do.

  # NOTE: port numbers from 0-1024 are considered well-known and reserved for
  # system use. Port numbers in the range 49000-65535 are ephemeral ports that
  # may be used by services that don't operate on pre-defined port numbers but
  # need ports for temporary purposes.
  # Safe to use port numbers in the range 1025-48999

  # Next, we let the Server listen — this means that the socket is marked as a
  # "passive socket", which is a socket that may be used to accept an incoming
  # connection request using the accept(2) syscall. The argument to the listen
  # method is a number that represents the maximum backlog of pending connection
  # requests that we want our server to tolerate. If our server socket is busy
  # handling another connection, new connection requests will be put into a
  # listen queue, and the size of this queue is exactly this backlog number.
  max_backlog = Socket::SOMAXCONN # socket max connections
  server.listen max_backlog

  # Currently, our server is marked as passive and may now accept connections.
  # We use the Socket#accept to do this:
  remote_socket, remote_socket_addrinfo = server.accept
  # remote_socket is a new Socket instance that represents the remote endpoint
  # and remote_socket_addrinfo is an instance of the Addrinfo class. Above, we
  # used the Socket#pack_sockaddr_in to pack data into an addrinfo struct to
  # bind the server socket to a (port, address) pair, but we could have also
  # used an Addrinfo object as well, and this is exactly what Socket#accept
  # returns (along with another Socket object).

  # Socket#accept BLOCKS while it waits for a remote connection.
  # In another terminal, execute this command which uses the `netcat` utility
  # (which I believe most linux machines come with by default, aliased as `nc`
  #
  # $ echo ohai | nc localhost 4481
  #
  # Then come back to the terminal that you ran the above code in, and you
  # should see that the server.accept call is no longer blocking the main
  # thread.

  # Let's take stock of what we have right now:
  # - server: Socket object that represents a 
  # - addr: packed data that encodes the local (IP address, port).
  # - remote_socket: Socket object that represents the remote host
  # - remote_socket_addrinfo: a Addrinfo object that encodes the remote (IP address, port) combo.

  # The server and addr were used to create a "listening" socket. This is a
  # connection endpoint that represents the point of entry to this process. It
  # does not itself encode a full connection. The remote_socket object however
  # does represent the actual connection, and we read/write to this object in
  # order to communicate with the other machine. The server socket is merely
  # here to redirect incoming connections to a new socket on this machine so
  # that remote clients may communicate with this machine.
  print 'Server class: '
  p server.class

  print 'Remote class: '
  p remote_socket.class

  print 'Server fd: '
  p server.fileno

  print 'Remote fd: '
  p remote_socket.fileno

  print 'Server local addr: '
  p server.local_address

  print 'Remote local addr: '
  p remote_socket.local_address

  print 'Remote remote address: '
  p remote_socket.remote_address

  # We may close a socket using the Socket#close method:
  # remote_socket.close
  #
  # This calls close(2) under the hood, which is a syscall that closes an open
  # file descriptor.
  # When this program exits, the OS will close all open file descriptors for us
  # but we should still cleanup these fds because, well, a long-lived server
  # program will persist beyond the closing of a client connection. It is a
  # good programming practice to clean up after yourself — a server may
  # actually run out of file descriptors if it never closes its connections!
  # See Process.getrlimit and Process.setrlimit

  # But, given that sockets are bidrectional, it is possible to close just one
  # end of the channel:
  # We may no longer write to the socket after the below line executes, but we
  # may still read from it.
  # Closing the write-end of a (TCP) stream will send an EOF to the other end
  # of the socket.
  remote_socket.close_write
  # We may no longer read from the socket (but may still write if we haven't
  # closed the write-end):
  remote_socket.close_read

  # NOTE: Regarding TCP socket connections:
  # close_read and close_write make use of shutdown(2), as oppoesed to close(2)
  # which the Socket#close method uses. This is significant because it is
  # possible to create copies of fds using Socket#dup or Process#fork, which
  # both duplicate the underlying file descriptors of the Socket objects in the
  # current process. Thus: - close(2) will close the socket instance on which
  # it's called, but if there are other copies of the socket in the system,
  # then those will NOT be closed and the underlying resources will not be
  # reclaimed -> other copies of the connection may still exchange data with
  # the remote host - shutdown(2), in addition to gracefully shutting down the
  # TCP connection by sending EOF to the other endpoint, will fully shut down
  # communication on the current socket and other copies of it, thereby
  # disabling all comms happening on the current instance as well as any
  # copies.
  #
  # BUT, shutdown(2) does not reclaim resources used by the socket. Each
  # individual socket instance must still be closed to complete the server
  # lifecycle.
  #
  # In other words, shutdown, finish reading from the socket if there is
  # anything left to read, THEN close your sockets when you are done with them.
  # You have the option of doing a close_read or close_write
  # (shutdown(2)) if you wish, but just make sure you at least close_write or
  # execute a full shutdown, then close the fd

  remote_socket.close

  # Finally done! So much for socket basics.
end

# The Server Loop
module ServerLoop
  <<SERVERLOOP
  # Create the server socket.
  server = Socket.new(:INET, :STREAM)
  addr = Socket.pack_sockaddr_in(4481, '0.0.0.0')
  server.bind(addr)
  server.listen(128)
  # Enter an endless loop of accepting and
  # handling connections.
  loop do
    connection, _ = server.accept
    # handle connection
    connection.shutdown
    connection.close
  end
SERVERLOOP
end

# Lets not do all that stuff above. We usually like to live at a higher level
# in ruby.
module TCPSocketAbstractions
  if false
    # Instead of all this:
    # socket = Socket.new(:INET, :STREAM)
    # addr = Socket.pack_sockaddr_in(4481, '0.0.0.0')
    # socket.bind(addr)
    # socket.listen(5)

    # We can just write this. If we need to increase the listen queue backlog
    # size, we can just call server.listen(BIGGER_NUM) after creating:
    server = TCPServer.new(4481)

    # Additionally, if we want to handle both IPv4 and IPv6, then we can do this,
    # which returns an array of 2 sockets that are bound and may listen on the
    # same port:
    servers = Socket.tcp_server_sockets(4481)

    # Besides constructing servers, we also have beautiful methods for handling
    # the accept loop:
    Socket.accept_loop(server) do |conn|
      # handle connection
      conn.close
    end

    # Note that connections are not automatically closed at the end of each block
    # The args that get passed into the block are the exact same ones that are
    # returned from a call to accept (Note that accept on TCPServer objects does
    # not return an Addrinfo object as well, just the new Socket.

    # Socket.accept_loop allows you to pass MULTIPLE listening sockets to it,
    # which goes really well with Socket.tcp_server_sockets.

    # Finally, we saved best for last:
    Socket.tcp_server_loop(4481) do |conn|
      # handle connection
      conn.close
    end
  end
end

# A little packet sniffer
module PacketSniffer
  5.times { puts }
  puts("=" * 80)
  puts "Use the following command (requires root privelges) to run a little packet sniffer."
  puts "Assumes ETH_P_IP = 0x0800. See /usr/include/linux/if_ether.h for available protocol numbers:"
  puts 'sudo ruby ./tcp_sockets.rb --sniffer'
  if ARGV.include? '--sniffer'
    ETH_P_IP = 0x0800

    sock = Socket.new(
      Socket::AF_PACKET,
      Socket::SOCK_RAW,
      [ETH_P_IP].pack("S>").unpack1("S")
    )

    puts "Listening for IPv4 Ethernet frames. Send SIGINT (ctrl + C) to kill process."
    sleep 3

    loop do
      # 65535 = 0xFFFF, maxbytes to read from socket
      data, addr = sock.recvfrom(65_535)

      puts "Received frame:"
      puts " bytes: #{data.bytesize}"
      puts " addr: #{addr.inspect}"
      puts "\n"
    end
  end
end

# rubocop:enable Style/StringLiterals
