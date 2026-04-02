# IDEA: Ruby CLI Chess

# This program will consist of a client program and a server program. A running
# server hosts a match-making lobby that clients can connect to. When a client
# connects, they may request the server to match them with another player to
# play a game of chess. The server will match players on a FIFO basis because
# let's not implement complex match-making for a game that no one will actually
# play. Players will be assigned white or black at random. The server will use
# TCP Sockets to facilitate IPC between clients, using the server as a
# centralized intermediary.

# When a game has been initiated between two players, they will be presented
# with two windows: a game window and a chat window, with an additional status
# line indicating important information about the game, such as last move or if
# a king is in check. Players will be able to send messages to each other at
# any time.

=begin
┌──────────────────────┐┌──────────────────────────────────────────────┐
│1 ♜ ♞ ♝ ♛ ♚ ♝ ♞ ♜     ││ STATUS: White played e4                      │
│2 ♟ ♟ ♟ ♟   ♟ ♟ ♟     │├──────────────────────────────────────────────┤
│3                     ││ Player1: Bro ur trash                        │
│4         ♟           ││ Player2: no u                                │
│5                     ││ Player1: whatever man                        │
│6                     ││ Player2: get good                            │
│7 ♙ ♙ ♙ ♙ ♙ ♙ ♙ ♙     ││                                              │
│8 ♖ ♘ ♗ ♕ ♔ ♗ ♘ ♖     ││                                              │
│  a b c d e f g h     ││                                              │
└──────────────────────┘└──────────────────────────────────────────────┘
=end

# Players will be able to switch the currently focused window between the game
# window and the chat window at any time using the <TAB> key. In the game
# window, players will be able to navigate the chess board using vim-like
# keyboard motions:
#   - 'h' to move the cursor one position left
#   - 'H' to move the cursor to the left-most side of the board
#   - 'j' to move the cursor one position down
#   - 'J' to move the cursor to the bottom-most side of the board
#   - 'k' to move the cursor one position up
#   - 'K' to move the cursor to the top-most side of the board
#   - 'l' to move the cursor one position right
#   - 'L' to move the cursor to the right-most side of the board

# During a player's turn, they will have the ability to move the game-board
# cursor over one of their pieces and move that piece to a legal position on
# the board. A player must press <SPACE> over one of their pieces to select
# that piece, then move the cursor to a valid position, then press <SPACE>
# again to execute the move. They can cancel the current selection by pressing
# ESC. A player may not modify the board when it is not their turn, but they
# can still explore the board with their cursor. At any time, when the game
# board window is in focus, if a player moves the cursor over any piece, there
# will be color hints indicating the legal moves of that piece.

# Command-line Interface:
#
# To start the client:
# $ ruby rbchess.rb --client my_identifying_name_with_no_spaces
#
# To start the server:
# $ ruby rbchess.rb --server my_identifying_name_with_no_spaces
#
#
#
#
#
#
# Message flow: Assume that Client and Server have successfully
# handshaked, that the Server is always correct, and that the clients
# implement the protocol correctly and send logically valid messages

# (Server requests client to echo back a time stamp.
# Server: { type: echo_req, value: TIME_STAMP } -> Client
# Client: { type: echo_reply, value: TIME_STAMP } -> Server

# (Client is prompted to enter their name and confirm they want to be matched,
# initiating a join request message)
# Client: { type: join_request, value: name } -> Server
# Server: { type: ack, value: join_request } -> Client

# (server matches client with another client waiting)
# Server: { type: join_success, value: PEER_NAME } -> Client

# (server sets up a chess game instance between them)
# Server: { type: game_ready, value: COLOR } -> ClientA, ClientB

# (client messages peer a glhf)
# ClientA: { type: msg, value: "glhf" } -> Server
# Server: { type: msg_relay, value: "glhf" } -> ClientB
# ClientB: { type: ack, value: MSG_RELAY } -> Server
# Server: { type: message_success } -> ClientA, ClientB

# (ClientA makes a move)
# ClientA: {type: move_request, value: XY } -> Server
#
# (Server receives move message, validates and accepts)
# Server: { type: board_update, value: BOARD } -> ClientA, ClientB
#
# 
#
#
#
#
#
#
#
#
#
#
