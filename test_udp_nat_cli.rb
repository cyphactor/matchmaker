#!/usr/bin/env ruby

require 'socket'

node_id = ARGV[0]
remote_node_id = ARGV[1]

class MatchMaker
  def initialize
    @s = UDPSocket.new
    @s.bind('', 8341)
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
    if action == 'connect' && response == 'success'
      puts "Received external ip (#{rem_ip}), port (#{rem_port}), mode (#{mode})"
      if mode == 'listener'
        puts "Punching hole in firewall for UDP host (#{rem_ip}) and port (#{6311})"
        punch = UDPSocket.new
        punch.bind('', 6311)
        punch.send('', 0, rem_ip, 6311)
        punch.close
        puts "Punched hole."

        puts "Listening for data"
        # Bind for receiving
        udp_in = UDPSocket.new
        udp_in.bind('0.0.0.0', 6311)
        puts "Binding to local port 6311"

        loop do
          # Receive data or time out after 5 seconds
          if IO.select([udp_in], nil, nil, rand(4))
            data = udp_in.recvfrom(1024)
            remote_port = data[1][1]
            remote_addr = data[1][3]
            puts "Response from #{remote_addr}:#{remote_port} is #{data[0]}"
          end
        end
      else if mode == 'initiator'
        udp_out = UDPSocket.new
        udp_out.bind('', 6311)
        loop do
          udp_out.send("time:#{Time.now.to_s}", 0, rem_ip, 6311)
          sleep 2
        end
      else
        puts "ERROR: Uknown connection mode"
      end
    end
  end
end

mm = MatchMaker.new
if mm.register(node_id)
  mm.connect(remote_node_id)
end

