Here’s a **clean, reusable, production-style architecture** for:

* ✔️ Client objects
* ✔️ A TUI organized around an **async UDS socket reader**
* ✔️ A protocol built on **JSON-RPC 2.0**

All examples are **short**, conceptual, and Ruby-ish — not full implementations (as you prefer).

---

# 1. **Client Objects — Architecture**

## 🧩 Core Idea

Each client gets **two objects**:

1. **ClientConnection** → wraps the UNIXSocket
2. **ClientSession** → stores state, username, room, etc.

Connections are ephemeral. Sessions are logical state.

---

## `ClientConnection`

Wraps the UNIX socket and handles:

* reading/writing JSON-RPC messages
* buffering partial reads
* notifying a handler when a complete message arrives

```ruby
class ClientConnection
  attr_reader :socket, :session

  def initialize(socket, session, on_message:)
    @socket = socket
    @session = session
    @buffer = +""
    @on_message = on_message  # callback: proc { |session, msg| ... }
  end

  # Write a JSON-RPC message
  def send_rpc(method:, params:, id: nil)
    msg = {
      jsonrpc: "2.0",
      method: method,
      params: params,
      id: id
    }.to_json + "\n"  # line-delimited JSON-RPC
    socket.write(msg)
  end

  # Called when IO.select says the socket is readable
  def read_available
    chunk = socket.read_nonblock(4096)
    @buffer << chunk

    while (line = @buffer.slice!(/.*?\n/))
      msg = JSON.parse(line, symbolize_names: true)
      @on_message.call(session, msg)
    end
  rescue IO::WaitReadable
    # no-op
  rescue EOFError
    session.disconnect!
  end
end
```

---

## `ClientSession`

Holds logical state only.
Knows nothing about sockets.

```ruby
class ClientSession
  attr_accessor :id, :matched_with, :username

  def initialize(id)
    @id = id
    @matched_with = nil
    @username = nil
  end

  def disconnect!
    puts "Client #{id} disconnected"
  end
end
```

---

# 2. **Server Structure (non-blocking, UDS)**

Server uses:

* `UNIXServer`
* a single event loop
* `IO.select` to manage many clients
* line-delimited JSON per message

```ruby
class ChatServer
  def initialize(path)
    File.unlink(path) if File.exist?(path)
    @server = UNIXServer.new(path)
    @clients = {}
    @next_id = 1
  end

  def run
    loop do
      readable = IO.select([@server] + @clients.keys)&.first
      next unless readable

      readable.each do |sock|
        if sock == @server
          accept_client
        else
          @clients[sock].read_available
        end
      end
    end
  end

  def accept_client
    socket = @server.accept_nonblock
    id = @next_id += 1
    session = ClientSession.new(id)

    conn = ClientConnection.new(
      socket,
      session,
      on_message: method(:handle_message)
    )

    @clients[socket] = conn
    puts "Client #{id} connected"
  end

  # msg = { jsonrpc:, method:, params:, id: }
  def handle_message(session, msg)
    case msg[:method]
    when "match.request" then handle_match_request(session)
    when "chat.send" then relay_message(session, msg[:params][:text])
    else
      puts "Unknown method: #{msg[:method]}"
    end
  end

  # these are just conceptual:
  def handle_match_request(session)
    # store waiting clients / match logic here
  end

  def relay_message(session, text)
    # find partner, send RPC, etc.
  end
end
```

Server is now a JSON-RPC router and matchmaker.

---

# 3. **Client-Side TUI + Async Reader (UNIX socket)**

The client TUI needs:

* a **main event loop**
* a **reader thread** (or fiber)
* channels/queues for passing messages into the UI

This pattern is standard:

```
          +----------------------+
          |   Reader Thread      |
          | reads socket         |
          | parses JSON-RPC      |
          | pushes to queue      |
          +----------+-----------+
                     |
                     v
         +-----------+------------+
         |         TUI Loop       |
         |  draws windows         |
         |  handles keyboard      |
         |  processes queue msgs  |
         +------------------------+
```

---

## Example Client (conceptual)

### The async socket reader

```ruby
class AsyncSocketReader
  def initialize(socket, queue)
    @socket = socket
    @queue = queue
    @buffer = +""
  end

  def start
    Thread.new do
      loop do
        begin
          data = @socket.readpartial(4096)
          @buffer << data

          while (line = @buffer.slice!(/.*?\n/))
            msg = JSON.parse(line, symbolize_names: true)
            @queue << msg
          end
        rescue EOFError
          @queue << :disconnect
          break
        end
      end
    end
  end
end
```

### The TUI Loop (using TTY::Reader + TTY::Screen)

```ruby
require "tty-reader"
require "tty-screen"

class ChatClientUI
  def initialize(socket)
    @socket = socket
    @queue = Queue.new

    @reader = TTY::Reader.new
    @async_reader = AsyncSocketReader.new(socket, @queue)
  end

  def run
    @async_reader.start

    loop do
      # Non-blocking keyboard check
      if @reader.ready?
        key = @reader.read_keypress
        handle_key(key)
      end

      # Process server messages
      process_messages

      # Redraw UI at ~60 fps
      sleep(0.016)
    end
  end

  def handle_key(key)
    case key
    when "j" then move_cursor_down
    when "k" then move_cursor_up
    when :ctrl_c then exit
    else
      handle_typing(key)
    end
  end

  def process_messages
    until @queue.empty?
      msg = @queue.pop
      case msg
      when :disconnect
        show_status("Disconnected from server")
        exit
      else
        handle_rpc(msg)
      end
    end
  end

  def handle_rpc(msg)
    case msg[:method]
    when "chat.receive"
      add_chat_message(msg[:params][:text])
    when "match.found"
      show_status("Matched with #{msg[:params][:username]}")
    end
  end
end
```

This gives you:

* Vim-style keybindings
* Nonblocking socket IO
* TUI updated at regular intervals
* JSON-RPC messages delivered via `Queue`

**This is the correct architecture for a TUI with IPC.**

---

# 4. **JSON-RPC Wire Format**

All messages look like:

```json
{"jsonrpc":"2.0","method":"chat.send","params":{"text":"hello"},"id":42}
```

You can distinguish:

* **notifications** → no `id`
* **requests** → require response
* **responses** → return to a request with same `id`

Example request:

```ruby
conn.send_rpc(
  method: "chat.send",
  params: { text: "hello world" }
)
```

Example server → client notification:

```ruby
conn.send_rpc(
  method: "chat.receive",
  params: { text: "Someone says hi" }
)
```

---

# If you want, I can also give you:

✔ A full JSON-RPC router implementation
✔ A matchmaking subsystem (queue, pairs, state machine)
✔ A clean protocol spec for your chat system
✔ How to organize windows in your TUI cleanly (TTY::Box grid manager)
✔ How to handle multi-client broadcast
✔ How to implement timeouts, pings, reconnection
✔ How to wrap the TUI in a single `Curses`-like layout engine without using curses

Tell me which of these you want next.
