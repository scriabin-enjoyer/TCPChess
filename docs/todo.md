## Phase 0: Protocol

Figure out the application protocol. Should specify complete communication
semantics that supports all features of chess with chat.

ONGOING:
- [] Implement SYSTEM type message
    - [x] echo req/reply, ping/pong,  bye
    - [x] join game, queued, join success, game disconnect, leave game, gamestart, leavegame
    - [] ack, info, error (TBD later)
    - [] State transition diagrams
- [x] Implement first draft of a TLV Parser

LATER:
- [] Implement GAME type messages (Doesn't need to be complete, just understand
     the idea)

## Phase 1: Reactor Skeleton, Connection Wrappers

Implement the main reactor loop and connection logic, without concern for other
aspects of the entire application. We should have a working echo server once
this is complete.

- [x] Implement Server class (reactor):
    - [x] TCP Server setup
    - [x] Resource allocation, TCP options (remember SOREUSEADDR)
    - [x] Shutdown cleanup
    - [x] IO.select loop
    - [x] invoke r/w callbacks
    - [] Tests:
        - [] initialize and setup logic
        - [] io registration (make sure filled r/w buffers are properly added)
        - [] handle_readable paths
        - [] shutdown logic
        - [] Integration tests with real clients
- [] Implement Parser and Message Generators
    - [x] learn how to set up rake
    - [x] implement parse_tlv and serialize_tlv
    - [x] setup rake and minitest
    - [x] write tests for parse_tlv
- [] Implement Connection class:
    - [] Interface with Server
    - [] Interface with Event Layer
    - [] State management
    - [] Connection health, status routines, 
    - [] Figure out keep-alives and timeouts

## Phase 2: Event Pipeline, Protocol Integration

Parse bytes from Connection layer read buffers, emit event objects (probably
just use a hash here), methods to receive events are push them to write queues
on the Connection objects. 

## Phase 3: Application Container

## Phase 4: Chess Logic

## Phase 5: Error Handling, Edge Cases
 
## Phase 6: Client
 
## Last Phase: Testing, Performance Profiling

- [] Headless Client
- [] Latency Testing
- [] Resource Exhaustion
- [] Profiling
