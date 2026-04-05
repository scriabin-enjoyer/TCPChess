### My Protocol: High Level Overview

First, we list the requirements for this application:  

This application implements a game server. This server has the ability to
accept client connections, who, once connected, may peruse various games that
the server allows users to play. There will only be one fully implemented game
that the server supports: Chess. Before starting this project, I did want to
also see if I could implement Scrabble as well, because I like Scrabble.
However, considering the amount of work that would go into implementing another
game on top of Chess which is already pretty big, I probably won't do this
(maybe in the future though).

#### Top Level Message Types

The protocol will support 2 top-level message types:
    - a SYSTEM type
    - a GAME type

Each message type is intended to be an entirely separate system, and no 2 types
should be used to communicate between the client and server. In other words:
    - SYSTEM messages must be replied with SYSTEM messages
    - GAME messages must be replied with GAME messages

#### SYSTEM Type

The SYSTEM message type is used for exchanging information to manage the
control plane between the client and server: to manage the connection session
between the client and server,  and to serve as an entry/exit point for client
connections into game lobbies that the server supports. The value field of this
message type may contain op codes to execute. The op codes that the SYSTEM type
should support should be the following:

- ECHO_REQ, ECHO_REPLY: measure RTT
- PING, PONG: keepalive, check responsiveness of peer
- JOIN_GAME, QUEUED, JOIN_SUCCESS: game lobby entry
- ACK: acknowledgement of receipt
- GAME_START: transition to "game" mode
- GAME_DISCONNECT: inform client they were disconnected from a game
- QUIT: session termination
- ERROR: generic error for protocol violations, malformed 

#### GAME Type

The GAME type is used to define a custom protocol for a specific game that the
server may want to support. For this server, I will only implement Chess, so I
will outline some possible chess-related message types here:
- BOARD_UPDATE
- MOVE_REQUEST
- MOVE_VALID
- ERROR
- GAME_OVER (checkmate, stalemate, forfeit)
- RESYNC_BOARD
- ACK
- CHATMSG: client sends a message to the game
- CHATMSG_RELAY: server relays a message from a client to other clients in the game
- CHATMSG_ACK: clients send acknowledgement of receipt of a MSG_RELAY
- CHATMSG_ERROR: generic error type to indicate errors related to CHAT
