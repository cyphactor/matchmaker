#!/usr/bin/env ruby

require 'socket'

# remote_node_id = ARGV.first
remote_node_id = 'brian'

NODE_ID = 'drew'

class MatchMaker
  def initialize
    @s = UDPSocket.new
    # s.bind('', 8341)
    @host = 'util.devscapades.com'
    @port = 9523
    @payload_size = 16
  end

  def register(node_id)
    @s.send("register:#{node_id}", 0, @host, @port)
    payload, sender = @s.recvfrom(@payload_size)
    action, data = payload.split(':')
    if action == 'register' && data == 'success'
      puts "Successfully registered '#{NODE_ID}'."
      return true
    else
      return false
    end
  end

  def connect(remote_node_id)
    puts "Trying to connect to '#{remote_node_id}'."
    @s.send("connect:#{remote_node_id}", 0, @host, @port)
    payload, sender = @s.recvfrom(@payload_size)
    action, data = payload.split(':')
    puts action
    puts data
  end
end

mm = MatchMaker.new
if mm.register(NODE_ID)
  mm.connect(remote_node_id)
else
  puts "ERROR: Failed to register successfully."
end

