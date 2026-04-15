# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../lib/protocol/main'

module ProtocolHelper
  def generate_byte
    rand(0..255).chr.b
  end

  def generate_2bytes
    type = rand(0..255).chr.b
    length = rand(1..255).chr.b
    type + length
  end
end
