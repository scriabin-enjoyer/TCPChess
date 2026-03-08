# frozen_string_literal: true

require_relative 'server'
require_relative 'client'
require_relative 'message'
require_relative 'ui'

test_function = ARGV.first.downcase

if test_function == 'server'
  TCPChatApp::Server.new.run
elsif test_function == 'client'
  client = TCPChatApp::Client.new
end
