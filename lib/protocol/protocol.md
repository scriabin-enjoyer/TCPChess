# My Game Server Protocol Spec v0.1

## Contents
0. Introduction
1. Overview: Transport & Framing
2. Message Structure
3. SYSTEM: Control Plane  
    3.1 Message Formats  
    3.2 Error Codes  
    3.3 Communication Semantics   
4. GAME: Application Plane (Chess)  
    4.1 Message Formats  
    4.2 Error Codes  
    4.3 Communication Semantics  
5. Connection Lifecycle

## 0. Introduction
This following protocol implements the syntax, semantics, and messaging formats
of a generic "Game Server": clients may connect to the server which hosts
various multi-player terminal game applications. Once connected, clients may
browse the various games that the server supports and choose to join a lobby
for a specific game. As a prototype, the main game that this server should
support is chess, although other games may be added so long as they conform to
the message formats and communication semantics outlined in this specification.

The protocol supports 2 top-level message types:
- a SYSTEM type, which refers to a collection of concretely defined message
formats and rules for exchanging SYSTEM-level messages between client and
server, used to manage the connection session between the client and server
- an abstract GAME type, which allows a developer to implement a game-specific
protocol on top of this protocol. This specification will outline an example
protocol that may be used to implement the game of chess, however, various
other types of games may be implemented as well.

Each of these top-level message types is intended to be an entirely separate
system, and no 2 types should be used to communicate between the client and
server. In other words:
- SYSTEM messages must be replied with SYSTEM messages
- GAME-specific messages must be replied with GAME-specific messages

However, specific GAME applications may utilize the services provided by the
SYSTEM messages.

## 1. Overview: Transport & Framing
- Transport: TCP
- Encoding: Binary
- Framing: Type-Length-Type-Value
- Maximum Message Size: 257 bytes
- Minimum Message Size: 3 bytes

## 2. Message Structure
Each message consists of 3 fixed length fields and 1 variable length field:
- **Type1** (1 byte): specifies a top-level message type (SYSTEM or GAME)
- **Length** (1 byte): specifies the length of the **Type2** and **Value**
fields in bytes
- **Type2** (1 byte): specifies a game-specific or system-level message type
- **Value** (0-254 bytes): payload data

### 2.1 Type1 Field
- Exactly 1 byte
- Representation: unsigned 8-bit integer
- If the value of this field is `0xFF`, then this indicates a SYSTEM-level
message.
- If the MSB of this field is 0, then this field indicates a specific GAME
type that the server may support. 7 bits allows the protocol to support 128
different games (i.e. 128 different GAME type values).
- If the value of this field is not `0xFF` or if it is not a supported GAME
value, then the server should reject the client that sends such a message.

### 2.2 Length Field
- Exactly 1 byte
- Representation: unsigned 8-bit integer
- Indicates the length of the **Type2** field plus the length of the **Value**
field.
- The minimum value of this field must be `0x01`
- The maximum value of this field is `0xFF`:  
    -> `length(Type2) + length(Value) <= 255`

### 2.3 Type2 Field
- Exactly 1 byte
- Representation: unsigned 8-bit integer
- Indicates a SYSTEM-specific or GAME-specific op-code

### 2.4 Value Field
- Variable length, 0-254 bytes
- Representation: protocol-specific
- Contains payload data relevant to the **Type2** field of the message

## 3. SYSTEM: Control Plane  

### 3.1 Message Formats  
The SYSTEM message type is used for exchanging information to manage the
control plane between the client and server: to manage the connection session
and to serve as an entry/exit point for client connections into game lobbies
that the server supports.

#### 3.1.1 Messages for client-server connectivity:

**ECHO_REQ**: Initiated by Server to measure RTT of a client.
- Type1 must be `0xFF`
- Length must be `0x0D`
- Type2 must be `0x01`
- Value must be 12 ASCII encoded bytes representing a UTC timestamp as
`"HH:MM:SS:sss"` (hour, minute, second, millisecond)

**ECHO_REPLY**: Initiated by Client to respond to ECHO_REQ. Must not be sent
before receiving an ECHO_REQ from server.
- Type1 must be `0xFF`
- Length must be `0x0D`
- Type2 must be `0x02`
- Value MUST be exactly the 9 bytes that were received in the most recent
ECHO_REQ message

**PING**: Initiated by Server to ping for client responsiveness.
- Type1 must be `0xFF`
- Length must be `0x01`
- Type2 must be `0x03`
- Value field must be omitted

**PONG**: Initiated by Client to respond to Server Ping. Must not be sent
before receiving a PING from server.
- Type1 must be `0xFF`
- Length must be `0x01`
- Type2 must be `0x04`
- Value field must be omitted

**BYE**: Initiated by Client or Server to indicate disconnection. May be sent
at any time. The Value field is optional and may contain arbitrary bytes
intended to be read as an ASCII encoded string.
- Type1 must be `0xFF`
- Length must be in the range `0x01-0xFF`
- Type2 must be `0x05`
- Value field may be omitted or contain up to 254 bytes.

#### 3.1.2 Messages for managing game lobby state:

**JOIN_GAME**: Initiated by Client to request to join a specific game offered
by the server. Must not be sent if Client is already in a game. The Value field
should represent one of the specific GAME-types that the server supports.
- Type1 must be `0xFF`
- Length must be `0x02`
- Type2 must be `0x06`
- Value must be a valid 1 byte GAME identifier in the range
`0b00000001`-`0b01111111`

**QUEUED**: Initiated by Server to inform Client their **JOIN_GAME** request is
being processed. Must not be sent before receiving a **JOIN_GAME** from Client.
The Value field should represent the Value field of a **JOIN_GAME** message
that a Client sent.
- Type1 must be `0xFF`
- Length must be `0x02`
- Type2 must be `0x07`
- Value must be a valid 1 byte GAME identifier in the range
`0b00000001`-`0b01111111`. 

**JOIN_SUCCESS**: Initiated by Server to inform Client that they have
successfully joined a game lobby. Must not be sent before sending a **QUEUED**
message to the client. The Value field should represent the Value field of a
**JOIN_GAME** message that a Client sent.
- Type1 must be `0xFF`
- Length must be `0x02`
- Type2 must be `0x08`
- Value must be a valid 1 byte GAME identifier in the range
`0b00000001`-`0b01111111`

**GAME_START**: Initiated by Server to inform Client the game has started, and
that they may now send GAME-specific messages The Value field should represent
the Value field of a **JOIN_GAME** message that a Client sent.
- Type1 must be `0xFF`
- Length must be `0x02`
- Type2 must be `0x09`
- Value must be a valid 1 byte GAME identifier in the range
`0b00000001`-`0b01111111`

**GAME_END**: Initiated by Server to inform Client the game has ended and that
they may no longer send GAME-specific messages The Value field should represent
the Value field of a **JOIN_GAME** message that a Client sent.
- Type1 must be `0xFF`
- Length `0x02`
- Type2 must be `0x0A`
- Value must be a valid 1 byte GAME identifier in the range
`0b00000001`-`0b01111111`

**GAME_DISCONNECT**: Initiated by Server to inform Client they were
disconnected from a game but not from the server The Value field should
represent the Value field of a **JOIN_GAME** message that a Client sent.
- Type1 must be `0xFF`
- Length must be `0x02`
- Type2 must be `0x0B`
- Value must be a valid 1 byte GAME identifier in the range
`0b00000001`-`0b01111111`

**LEAVE_GAME**: Initiated by Client to inform Server they are leaving a game,
or to indicate they no longer wish to be **QUEUED** for a specific GAME The
Value field should represent the Value field of a **JOIN_GAME** message that a
Client sent.
- Type1 must be `0xFF`
- Length must be `0x02`
- Type2 must be `0x0C`
- Value must be a valid 1 byte GAME identifier in the range
`0b00000001`-`0b01111111`

#### 3.1.3 Formats for reliability, diagnostics, and server utilities

**ACK**: acknowledgement of receipt of a general message
- Specification TBD

**INFO**: general information exchange
- Type1 must be `0xFF`
- Length must be in the range `0x02`-`0xFF`
- Type2 must be `0x0E`
- Value may be any arbitrary sequence of bytes up to 254 bytes in length. This
field is intended to be interpreted as an ASCII encoded byte string.

**ERROR**: generic error for protocol violations. See below for error codes.
- Type1 must be `0xFF`
- Length must be `0x02`
- Type2 must be `0x0F`
- Value must be any value in the range `0x00`-`0xFF`

### 3.2 Info Codes, Error Codes
### 3.3 Communication Semantics

## 4. GAME Layer: Application Plane (Chess)  
### 4.1 Message Formats  
### 4.2 Error Codes  
### 4.3 Communication Semantics  

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

## 5. Connection Lifecycle

Connection States := IDLE | QUEUED | IN_GAME | CLOSED | UNRESPONSIVE

- IDLE means:
    - A client has recently connected to the server but has not sent any
    protocol messages
    - a client was in the QUEUED state or IN_GAME state but was disconnected
    from the game/matchmaking lobby via GAME_END, GAME_DISCONNECT, or
    LEAVE_GAME message
- QUEUED means:
    - a client was IDLE and then sent a JOIN_GAME message
- IN_GAME means
    - a client was QUEUED and then the server found a match for them and sent
    them a GAME_START message
- CLOSED means:
    - a client was in any state and then sent an ill-formed message (one that
    does not conform to this protocol)
    - a client was in the UNRESPONSIVE state for longer than a TBD timeout
    interval
    - a client was in any other state but was disconnected from the server via
    BYE message
- UNRESPONSIVE means:
    - a client has not sent any data for a TBD timeout interval
