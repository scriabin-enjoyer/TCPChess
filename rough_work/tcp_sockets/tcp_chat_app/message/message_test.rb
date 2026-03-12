# frozen_string_literal: true

require_relative 'message' # Assuming your code is in message.rb

def assert_equal(expected, actual, msg_name)
  if expected == actual
    puts "✅ [PASS] #{msg_name}"
  else
    puts "❌ [FAIL] #{msg_name}: Expected #{expected.inspect}, got #{actual.inspect}"
    exit 1
  end
end

module MessageTest
  include TCPChatApp::Message

  puts "Starting Protocol Tests..."
  puts "--------------------------"

  # --- NOP ---
  nop_bin = Generator.nop
  nop_out = Parser.nop(nop_bin)
  assert_equal(NOP_T, nop_out[:type], "NOP Type")
  assert_equal(NOP_L, nop_out[:length], "NOP Length")

  # --- ECHO_REQ ---
  ts = "123456"
  ereq_bin = Generator.echo_req(timestamp: ts)
  ereq_out = Parser.echo_req(ereq_bin)
  assert_equal(ECHO_REQ_T, ereq_out[:type], "ECHO_REQ Type")
  assert_equal(ts, ereq_out[:value], "ECHO_REQ Value")

  # --- ECHO_REPLY ---
  erep_bin = Generator.echo_reply(ts)
  erep_out = Parser.echo_reply(erep_bin)
  assert_equal(ECHO_REPLY_T, erep_out[:type], "ECHO_REPLY Type")
  assert_equal(ts, erep_out[:value], "ECHO_REPLY Value")

  # --- READY ---
  name = "Jabroni"
  ready_bin = Generator.ready(name)
  ready_out = Parser.ready(ready_bin)
  assert_equal(READY_T, ready_out[:type], "READY Type")
  assert_equal(name, ready_out[:value], "READY Value")

  # --- MSG ---
  text = "YOU ARE A LOSER AND I HATE YOU! 🫖"
  msg_bin = Generator.msg(text)
  msg_out = Parser.msg(msg_bin)
  assert_equal(MSG_T, msg_out[:type], "MSG Type")
  assert_equal(text.b.bytesize, msg_out[:length], "MSG Byte Length")
  assert_equal(text, msg_out[:value], "MSG Value")

  # --- MSG_RELAY ---
  relay_text = "Relayed Message"
  relay_bin = Generator.msg_relay(relay_text)
  relay_out = Parser.msg_relay(relay_bin)
  assert_equal(MSG_RELAY_T, relay_out[:type], "MSG_RELAY Type")
  assert_equal(relay_text, relay_out[:value], "MSG_RELAY Value")

  # --- RECEIPT ---
  m_type = MSG_T
  receipt_bin = Generator.receipt(m_type)
  receipt_out = Parser.receipt(receipt_bin)
  assert_equal(RECEIPT_T, receipt_out[:type], "RECEIPT Type")
  assert_equal(m_type, receipt_out[:value], "RECEIPT Value (Type Ack)")

  # --- QUIT ---
  quit_bin = Generator.quit
  quit_out = Parser.quit(quit_bin)
  assert_equal(QUIT_T, quit_out[:type], "QUIT Type")
  assert_equal(0, quit_out[:length], "QUIT Length")

  # --- SHUTDOWN ---
  sd_bin = Generator.shutdown
  sd_out = Parser.shutdown(sd_bin)
  assert_equal(SHUTDOWN_T, sd_out[:type], "SHUTDOWN Type")
  assert_equal(0, sd_out[:length], "SHUTDOWN Length")

  puts "--------------------------"
  puts "All tests passed successfully!"
end
