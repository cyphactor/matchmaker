#!/usr/bin/env ruby

require 'socket'

node_id = ARGV[0]
remote_node_id = ARGV[1]

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
      puts "Successfully registered '#{node_id}'."
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
if mm.register(node_id)
  mm.connect(remote_node_id)
else
  puts "ERROR: Failed to register successfully."
end

