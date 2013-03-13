#!/usr/bin/env ruby

require 'socket'

node_id = ARGV[0]
remote_node_id = ARGV[1]

PUNCH_PORT = 8342

class MatchMaker
  def initialize
    @s = UDPSocket.new
    #@s.bind('', 8341)
    @s.bind('', PUNCH_PORT)
    @host = 'util.devscapades.com'
    @port = 9523
    @payload_size = 16
  end

  def register(node_id)
    puts "Trying to register '#{node_id}'..."
    @s.send("register:#{node_id}", 0, @host, @port)
    puts "-- Sent registration request."
    payload, sender = @s.recvfrom(@payload_size)
    action, data = payload.split(':')
    if action == 'register' && data == 'success'
      puts "Successfully registered '#{node_id}'."
      return true
    else
      puts "Failed to register '#{node_id}'. Received response '#{payload}'."
      return false
    end
  end

  def connect(remote_node_id)
    puts "Trying to connect to '#{remote_node_id}'..."
    @s.send("connect:#{remote_node_id}", 0, @host, @port)
    payload, sender = @s.recvfrom(@payload_size * 10)
    action, response, rem_ip, rem_port, mode = payload.split(':')
    while action == 'connect' && response == 'pending' do
      print "."
      sleep 1
      @s.send("connect:#{remote_node_id}", 0, @host, @port)
      payload, sender = @s.recvfrom(@payload_size * 10)
      action, response, rem_ip, rem_port, mode = payload.split(':')
    end

    if action == 'connect' && response == 'success'
      puts "Received external ip (#{rem_ip}), port (#{rem_port}), mode (#{mode})"
      if mode == 'listen'
        puts "Punching hole in firewall for UDP host (#{rem_ip}) and port (#{rem_port})"
        @s.send('now-it-is-something', 0, rem_ip, rem_port)
        puts "Punched hole."

        puts "Listening for data"
        loop do
          # Receive data or time out after 5 seconds
          if IO.select([@s], nil, nil, rand(4))
            data = udp_in.recvfrom(1024)
            remote_port = data[1][1]
            remote_addr = data[1][3]
            puts "Response from #{remote_addr}:#{remote_port} is #{data[0]}"
          end
        end
      elsif mode == 'initiate'
        loop do
          @s.send("time:#{Time.now.to_s}", 0, rem_ip, rem_port)
          puts "Sent time to #{rem_ip}:#{rem_port}"
          sleep 2
        end
      else
        puts "ERROR: Uknown connection mode"
      end
    else
      puts "ERROR: Unkown connection response"
    end
  end
end

mm = MatchMaker.new
if mm.register(node_id)
  mm.connect(remote_node_id)
end

