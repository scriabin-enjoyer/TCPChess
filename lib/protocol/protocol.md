# My Game Server Protocol Spec v0.1.0

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
This following protocol implements the client-server communication semantics of
a "Game Server": clients may connect to the server which hosts various
multi-player terminal game applications. Once connected, clients may browse the
various games that the server supports and choose to join a lobby for a
specific game. As a prototype, the main game that this server should support is
chess, although other games may be added so long as they conform to the message
formats and communication semantics outlined in this specification.

The protocol supports 2 top-level message types:
- a SYSTEM type, which refers to a collection of concretely defined message
formats and rules for exchanging SYSTEM-level messages between client and
server, used to manage the connection session between the client and server
- an abstract GAME type, which allows one to implement a game-specific protocol
on top of this protocol. This specification will outline an example protocol
that may be used to implement the game of chess, however, various other types
of games may be implemented as well.

Each of these top-level message types is intended to be an entirely separate
system, and no 2 types should be used to communicate between the client and
server. In other words:
- SYSTEM messages must be replied with SYSTEM messages
- GAME messages must be replied with GAME messages

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
- **Type1**: specifies a top-level message type (SYSTEM or GAME)
- **Length**: specifies the length of the **Type2** and **Value** fields in
bytes
- **Type2**: specifies a game-specific or system-level message type
- **Value**: payload data

### 2.1 Type1 Field
- Exactly 1 byte
- If the value of this field is 0xFF, then this indicates a SYSTEM-level
message.
- If the MSB of this field is 0, then this field indicates a specific GAME that
the server supports. 7 bits allows the protocol to support 128 different games.
- Values in the range 0b10000000 to 0b11111110 are reserved. Clients that
transmit a **Type1** header in this range should be rejected by the server.

### 2.2 Length Field
- Exactly 1 byte
- Indicates the length of the **Type2** field plus the length of the **Value**
field.
- The minimum value of this field must be 1
- The maximum value of this field is 255:
    -> length(type2) + length(value) <= 255

### 2.3 Type2 Field
- Exactly 1 byte
- Indicates a system-specific or game-specific message type

### 2.4 Value Field
- Variable length, 0-254 bytes
- Contains payload data relevant to the types of the message

## 3. SYSTEM: Control Plane  

### 3.1 Message Formats  
The SYSTEM message type is used for exchanging information to manage the
control plane between the client and server: to manage the connection session
between the client and server,  and to serve as an entry/exit point for client
connections into game lobbies that the server supports. The value field of this
message type may contain op codes to execute. The op codes that the SYSTEM type
may support are be the following:

#### 3.1.1 Formats for client-server connectivity:

**ECHO_REQ**: Initiated by Server to measure RTT of a client
- Type1 must be 0xFF
- Length must be 0x0A
- Type2 must be 0x01
- Value MUST be 9 ASCII encoded bytes representing a UTC timestamp as
"HHMMSSsss" (hour, minute, second, millisecond)

**ECHO_REPLY**: Initiated by Client to respond to ECHO_REQ
- Type1 must be 0xFF
- Length must be 0x0A
- Type2 must be 0x02
- Value MUST be exactly the 9 bytes that were received in the most recent
ECHO_REQ message

**PING**: Initiated by Server to ping for client responsiveness
- Type1 must be 0xFF
- Length must be 0x01
- Type2 must be 0x03
- Value field must be omitted

**PONG**: Initiated by Client to respond to Server Ping
- Type1 must be 0xFF
- Length must be 0x01
- Type2 must be 0x04
- Value field must be omitted

**BYE**: Initiated by either Client of Server to indicate disconnection
- Type1 must be 0xFF
- Length must be in the range 0x01-0xFF
- Type2 must be 0x05
- Value field may contain arbitrary bytes, intended to be read as a UTF8
encoded string to indicate some message about why the sender closed the
connection. Suggested error codes and their meanings will be provided below, at
the end of section 3 (this section). A sender of this message is not required
to include this Value field in the message, and it may be omitted.

#### 3.1.2 Formats for Game Lobby state:

**JOIN_GAME**:
- Type1
- Length
- Type2
- Value

**QUEUED**:
- Type1
- Length
- Type2
- Value

**JOIN_SUCCESS**:
- Type1
- Length
- Type2
- Value

**LOBBY_DISCONNECT**:
- Type1
- Length
- Type2
- Value

**LEAVE_LOBBY**:
- Type1
- Length
- Type2
- Value

#### 3.1.3 Formats for state transition between SYSTEM and GAME:

**GAME_START**:
- Type1
- Length
- Type2
- Value

**GAME_END**:
- Type1
- Length
- Type2
- Value

#### 3.1.4 Formats for reliability, diagnostics, and server utilities

**ACK**: acknowledgement of receipt
- Type1
- Length
- Type2
- Value

**INFO**: general information exchange
- Type1
- Length
- Type2
- Value

**ERROR**: generic error for protocol violations, malformed 
- Type1
- Length
- Type2
- Value

### 3.2 Error Codes  

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
