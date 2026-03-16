# frozen_string_literal: true

# rubocop:disable all

module TCPChatAppServer
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
end
