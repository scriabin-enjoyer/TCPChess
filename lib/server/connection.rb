# frozen_string_literal: true

require_relative '../protocol/main'

# When to close a connection:
#   At the connection layer:
#   - When the remote peer closes their side (TCP FIN):
#     - EOFError
#   - Something went wrong at the Transport or Network layers:
#     - EPIPE: Tried to write to a socket that already closed
#     - ESHUTDOWN: We already shutdown writing
#     - ECONNRESET: Remote conn ungracefully 
#     - ETIMEDOUT: Connection timed out, remote peer no longer available
#     - ENOTCONN: 
#     - IOError: tried to write to closed stream
#
#   At the application layer:
#   - If they send malformed Protocol message
#   - If they send illogical Protocol message
#   - If they have not sent any data for specified timeout
#
# 

module MyGameServer
  module Server
    class Connection
      MAX_BUFF_SIZE = 2.5 * 1024

      def initialize(socket)
        @socket = socket.binmode
        @socket.setsockopt(:TCP, :NODELAY, true)
        @last_seen = Time.now
        @rx_buffer = String.new(encoding: "BINARY")
        @write_event_queue = []
      end

      def to_io
        @socket
      end

      def monitor_for_reading?
        # just return true for now why should this not just return true? if the
        # read end of this socket is closed then we shouldn't actually read it
        return false if closed?
        return false if @rx_buffer.bytesize >= MAX_BUFF_SIZE

        true
      end

      def monitor_for_writing?
        !@write_event_queue.empty?
      end

      def sock_addr
        @socket.remote_address.getnameinfo
      end

      def on_connect
        log :connection, "Client Connected: #{sock_addr}"
      end

      def close
        @socket.close
      end

      def closed?
        @socket.closed?
      end

      def teardown
        # Requires more logic when integrated more fully
        @socket.close
      end

      def fileno
        @socket.fileno
      end

      def on_readable
        data = @socket.read_nonblock(1024, exception: false)
        return if data == :wait_readable

        if data.nil?
          @socket.close
          return
        end

        @last_seen = Time.now
        @rx_buffer << data
        until (event = Protocol.parse_tlv(@rx_buffer)).nil?
          @write_event_queue << event
          @rx_buffer.slice!(0, event.bytesize)
        end
      rescue Errno::ECONNRESET
        # raised when we try to read from a connection 
        @socket.close
      rescue Errno::EOFError
        # read_nonblock raises this on EOF
        raise
      end

      def on_writable
        @write_event_queue.each { @socket.write it.to_wire }
        @write_event_queue.clear
      end
    end
  end
end

=begin
module SocketErrors
  ERR_DESC = {
    Errno::EACCES => "search permission is denied for a component of the prefix path or write access to the socket is denied",
    Errno::EADDRINUSE => "the sockaddr is already in use",
    Errno::EADDRNOTAVAIL => "the specified sockaddr is not available from the local machine",
    Errno::EAFNOSUPPORT => "the specified sockaddr is not a valid address for the address family of the specified socket",
    Errno::EALREADY => "a connection is already in progress for the specified socket",
    Errno::EBADF => "the socket is not a valid file descriptor",
    Errno::ECONNREFUSED => "the target sockaddr was not listening for connections refused the connection request",
    Errno::ECONNRESET => "the remote host reset the connection request",
    Errno::EFAULT => "the sockaddr cannot be accessed",
    Errno::EHOSTUNREACH => "the destination host cannot be reached (probably because the host is down or a remote router cannot reach it)",
    Errno::EINPROGRESS => "the O_NONBLOCK is set for the socket and the connection cannot be immediately established; the connection will be established asynchronously",
    Errno::EINTR => "the attempt to establish the connection was interrupted by delivery of a signal that was caught; the connection will be established asynchronously",
    Errno::EISCONN => "the specified socket is already connected",
    Errno::EINVAL => "the address length used for the sockaddr is not a valid length for the address family or there is an invalid family in sockaddr",
    Errno::ENAMETOOLONG => "the pathname resolved had a length which exceeded PATH_MAX",
    Errno::ENETDOWN => "the local interface used to reach the destination is down",
    Errno::ENETUNREACH => "no route to the network is present",
    Errno::ENOBUFS => "no buffer space is available",
    Errno::ENOSR => "there were insufficient STREAMS resources available to complete the operation",
    Errno::ENOTSOCK => "the socket argument does not refer to a socket",
    Errno::EOPNOTSUPP => "the calling socket is listening and cannot be connected",
    Errno::EPROTOTYPE => "the sockaddr has a different type than the socket bound to the specified peer address",
    Errno::ETIMEDOUT => "the attempt to connect timed out before a connection was made.",
  }
end
=end

# read_nonblock Errors:
#
# EAGAIN or EWOULDBLOCK: The  file descriptor fd refers to a socket and has been marked nonblocking (O_NONBLOCK), and the read would block.
#
# EBADF: fd is not a valid file descriptor or is not open for reading.
#
# EFAULT: buf is outside your accessible address space.
#
# EINTR: The call was interrupted by a signal before any data was read.
#
# EINVAL: fd  is  attached  to  an  object which is unsuitable for reading and
# either the address specified in buf, the value specified in count, or the
# file offset is not suitably aligned.
#
# EINVAL: fd was created via a call to timerfd_create(2) and the wrong size
# buffer was given to read(); see timerfd_create(2) for further  infor‐ mation.
#
# EIO: I/O  error.   This will happen for example when the process is in a
# background process group, tries to read from its controlling termi‐ nal, and
# either it is ignoring or blocking SIGTTIN or its process group is orphaned.
# It may also occur when there is a  low-level  I/O error  while  reading  from
# a disk or tape.  A further possible cause of EIO on networked filesystems is
# when an advisory lock had been taken out on the file descriptor and this lock
# has been lost.  See the Lost locks section of fcntl(2) for further details.
#
# EISDIR fd refers to a directory.
