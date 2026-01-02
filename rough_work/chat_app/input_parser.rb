# frozen_string_literal: true

# Parses Input
module InputParser
  # Remember we are trying to parse stuff life this:
  # 1 hello 2 asdkahsdk 3 aiyyaa
  # There are absolutely bugs in these patterns, but they are sufficient.
  MULTI_CLIENT_MESSAGE_RE = /(\d+)\s+([^0-9]+)/

  def parse_input(input)
    case input
    when 'quit'
      quit
    when MULTI_CLIENT_MESSAGE_RE
      messages_to_hash(input)
    else
      error
    end
  end

  private

  def quit
    { method: :quit }
  end

  def messages_to_hash(input)
    payload = {}

    input.scan(MULTI_CLIENT_MESSAGE_RE) do |client_id, text|
      payload[client_id] = text
    end

    {
      method: :messages,
      params: payload
    }
  end

  def error
    { method: :error }
  end
end
