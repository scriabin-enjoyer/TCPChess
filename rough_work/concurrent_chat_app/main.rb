# frozen_string_literal: true

require_relative './input_parser'
require_relative './client'
require_relative './server'
require_relative './stream_splitter'

# DRIVER
reader, writer = IO.pipe

stream_splitter = StreamSplitter.new(writer)
client = Client.new(stream_splitter)
server = Server.new(reader)

stream_splitter.start
server.start
client.start # main thread loops ("blocks") here

stream_splitter.shutdown
server.shutdown
client.byebye
