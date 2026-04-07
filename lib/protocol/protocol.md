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
5. Server Lifecycle
6. Client Lifecycle
7. Sequence Diagrams, State Machines

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
- If the value of this field is `0xFF`, then this indicates a SYSTEM-level
message.
- If the MSB of this field is 0, then this field indicates a specific GAME
type that the server may support. 7 bits allows the protocol to support 128
different games.
- The Value `0b00000000` and Values in the range `0b10000000` to `0b11111110`
are reserved. Clients that transmit a **Type1** header in this range should be
rejected by the server.

### 2.2 Length Field
- Exactly 1 byte
- Indicates the length of the **Type2** field plus the length of the **Value**
field.
- The minimum value of this field must be 1
- The maximum value of this field is 255:  
    -> `length(Type2) + length(Value) <= 255`

### 2.3 Type2 Field
- Exactly 1 byte
- Indicates a SYSTEM-specific or GAME-specific sub-type

### 2.4 Value Field
- Variable length, 0-254 bytes
- Contains payload data relevant to the types of the message

## 3. SYSTEM: Control Plane  

### 3.1 Message Formats  
The SYSTEM message type is used for exchanging information to manage the
control plane between the client and server: to manage the connection session
and to serve as an entry/exit point for client connections into game lobbies
that the server supports.

#### 3.1.1 Messages for client-server connectivity:

**ECHO_REQ**: Initiated by Server to measure RTT of a client
- Type1 must be `0xFF`
- Length must be `0x0C`
- Type2 must be `0x01`
- Value must be 12 ASCII encoded bytes representing a UTC timestamp as
`"HH:MM:SS:sss"` (hour, minute, second, millisecond)

**ECHO_REPLY**: Initiated by Client to respond to ECHO_REQ
- Type1 must be `0xFF`
- Length must be `0x0A`
- Type2 must be `0x02`
- Value MUST be exactly the 9 bytes that were received in the most recent
ECHO_REQ message

**PING**: Initiated by Server to ping for client responsiveness
- Type1 must be `0xFF`
- Length must be `0x01`
- Type2 must be `0x03`
- Value field must be omitted

**PONG**: Initiated by Client to respond to Server Ping
- Type1 must be `0xFF`
- Length must be `0x01`
- Type2 must be `0x04`
- Value field must be omitted

**BYE**: Initiated by Client or Server to indicate disconnection
- Type1 must be `0xFF`
- Length must be in the range `0x01-0xFF`
- Type2 must be `0x05`
- Value field may contain arbitrary bytes, and it may 0-254 bytes long. This
field is intended to be read as a UTF8 encoded string to indicate some message
about why the sender closed the connection. Suggested error codes and their
meanings will be provided below, at the end of section 3 (this section). A
sender of this message is not required to include this Value field in the
message, and it may be omitted.

#### 3.1.2 Messages for managing game lobby state:

**JOIN_GAME**: Initiated by Client to request to join a specific game offered by the server
- Type1 must be `0xFF`
- Length must be in the range `0b00000001`-`0b01111111`
- Type2 must be `0x06`
- Value

**QUEUED**: Initiated by Server to inform Client their JOIN_GAME request is being processed
- Type1 must be `0xFF`
- Length
- Type2 must be `0x07`
- Value

**JOIN_SUCCESS**: Initiated by Server to inform Client that they have successfully joined a game lobby
- Type1 must be `0xFF`
- Length
- Type2 must be `0x08`
- Value

**GAME_DISCONNECT**: Initiated by Server to inform Client they were disconnected from a game (but not the server)
- Type1 must be `0xFF`
- Length
- Type2 must be `0x09`
- Value

**LEAVE_GAME**: Initiated by Client to inform Server they are leaving a game
- Type1 must be `0xFF`
- Length
- Type2 must be `0x0A`
- Value

**GAME_START**: Initiated by Server to inform Client the game has started, and that the Server is now accepting GAME-specific messages
- Type1 must be `0xFF`
- Length
- Type2 must be `0x0B`
- Value

**GAME_END**: Initiated by Server to inform Client the game has ended and that they may no longer send GAME-specific messages
- Type1 must be `0xFF`
- Length
- Type2 must be `0x0C`
- Value

#### 3.1.3 Formats for reliability, diagnostics, and server utilities

**ACK**: acknowledgement of receipt
- Type1 must be `0xFF`
- Length must by `0x02`
- Type2 must be `0x0D`
- Value must be one byte in the range `0x01`-`0x0F` i.e. it must be some SYSTEM-level Type2 value specified in this document.

**INFO**: general information exchange
- Type1 must be `0xFF`
- Length must be in the range `0x02`-`0xFF`
- Type2 must be `0x0E`
- Value must be Length bytes in length and must 

**ERROR**: generic error for protocol violations, malformed 
- Type1 must be `0xFF`
- Length
- Type2 must be `0x0F`
- Value

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

## 5. Server Lifecycle

## 6. Client Lifecycle

## 7. Sequence Diagrams, State Machines
