## My Chess Protocol Spec v0.1.0

### 1. Transport & Framing
- Transport: TCP
- Encoding: UTF-8
- Framing: Type-Length-Value
- Maximum Message Size: 257
- Minimum Message Size: 2

### 2. Message Structure
Each message consists of 2 fixed length fields and 1 variable length field:
- **Type**   (1 Byte) specifies a message type
- **Length** (1 Byte) specifies the length of the payload (Value field) in octets
- **Value**  (0-255 Bytes) the actual payload

### 3. Client -> Server Events
- **echo request**: request server to echo back a reply
- **echo reply**: respond to an echo request from the server
- **join request**: request to join a game with another person
- **move**: attempt to execute a chess move.
- **message**: send chat message to peer client
- **quit**: leave game, automatic forfeit, shutdown server connection
- **receipt**: send message to server indicating receipt of some other message
type
- **error**: indicate some error

### 4. Server -> Client Events
- **echo request**: request client to respond with **echo reply**
- **echo reply**: respond to an **echo request** from the client
- **acknowledge**: acknowledge reeipt of a specific message
- **join success**: indicate to client that they were matched with a peer and
may now start playing chess and chatting
- **message relay**: relays a **msg** message sent from one client to its peer
client
- **shutdown**: inform client that the chat room is shutting down
- **error**: indicate some error

### 5. Message Types
1. **NOP**        := 0x00
1. **ECHO_REQ**   := 0x01
1. **ECHO_REPLY** := 0x02
1. **READY**      := 0x03
1. **MSG**        := 0x04
1. **MSG_RELAY**  := 0x05
1. **RECEIPT**    := 0x06
1. **QUIT**       := 0x07
1. **SHUTDOWN**   := 0x08

### 6. Message Formats

**NOP**: Initiated by any end-user of the protocol (client or server)
- Type MUST be 0x00
- Length MUST be 0x00
- Value MUST be omitted

**ECHO_REQ**: Initiated by the server user
- Type MUST be 0x01
- Length MUST be 0x06
- Value MUST be 6 ASCII encoded bytes representing a UTC timestamp as "HHMMSS"

**ECHO_REPLY**: Initiated by client user
- Type MUST be 0x02
- Length MUST be 0x06
- Value MUST be the Value of the previously received **ECHO_REQ** message

**READY**: Initiated by the server user
- Type MUST be 0x03
- Length MUST be in the range 0x01 - 0x0F
- Value MUST a UTF-8 encoded byte string exactly Length octets in length

**MSG**: Initiated by the client user
- Type MUST be 0x04
- Length MUST be in the range 0x01 - 0xFF
- Value MUST be a byte string exactly Length octets in length

**MSG_RELAY**: Initiated by the server user
- Type MUST be 0x05
- Length MUST be in the range 0x01 - 0xFF
- Value MUST be a byte string exactly Length octets in length

The Value field MUST faithfully represent the client message that the server
received. The server is not obligated to relay the exact bytes that it received
in a previous corresponding **MSG** message.

**RECEIPT**: Initiated by the client user
- Type MUST be 0x06
- Length MUST be 0x01
- Value MUST be in the range 0x00 - 0x07 indicating the most recent message
Type the client received from the server

**QUIT**: Initiated by the client user
- Type MUST be 0x07
- Length MUST be 0x00
- Value MUST be omitted

**SHUTDOWN**: Initiated by the server user
- Type MUST be 0x08
- Length MUST be 0x00
- Value MUST be omitted
