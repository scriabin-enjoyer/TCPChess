# frozen_string_literal: true

LOG_FILE = $stdout

def log(type, message)
  if type == :data
    p message
  else
    LOG_FILE.puts "[#{Time.now}][#{type.upcase}]: #{message}\n"
  end
end
