#!/usr/bin/env ruby

require 'socket'

node_id = ARGV[0]
remote_node_id = ARGV[1]

module MatchMaker
  NAT_DISCOVERY_HOST = 'util.devscapades.com'
  NAT_DISCOVERY_PORT_ONE = 9524
  NAT_DISCOVERY_PORT_TWO = 9525
  NAT_DISCOVERY_BIND_PORT = 8341
  NAT_DISCOVERY_PAYLOAD_SIZE = 32 

  class Client
    def initialize
      @nat_discovery_socket = UDPSocket.new
      @nat_discovery_socket.bind('', NAT_DISCOVERY_BIND_PORT)
    end

    def discover_nat_type
      loc_ip = get_local_ip

      external_ip_one, external_port_one = discover_first_external_ip_and_port

      if loc_ip == external_ip_one && NAT_DISCOVERY_BIND_PORT == external_port_one
        # We can assume that we are on the public network, or that we are on the
        # same network as the NAT discovery service, which should be on the public
        # internet.
        return :public
      else # some kind of NATing going on
        external_ip_two, external_port_two = discover_second_external_ip_and_port

        if external_port_one == external_port_two
          return :asymmetric
        else
          return :symmetric
        end
      end
    end

    private

    def discover_first_external_ip_and_port
      @nat_discovery_socket.send("NAT discovery request one", 0, NAT_DISCOVERY_HOST, NAT_DISCOVERY_PORT_ONE)
      payload, sender = @nat_discovery_socket.recvfrom(NAT_DISCOVERY_PAYLOAD_SIZE)
      external_ip_one, external_port_one = payload.split(':')
      return [external_ip_one, external_port_one]
    end

    def discover_second_external_ip_and_port
      @nat_discovery_socket.send("NAT discovery requset one", 0, NAT_DISCOVERY_HOST, NAT_DISCOVERY_PORT_TWO)
      payload, sender = @nat_discovery_socket.recvfrom(NAT_DISCOVERY_PAYLOAD_SIZE)
      external_ip_two, external_port_two = payload.split(':')
      return [external_ip_two, external_port_two]
    end

    def get_local_ip
      # turn off reverse DNS resolution
      orig_dnrl = Socket.do_not_reverse_lookup
      Socket.do_not_reverse_lookup = true

      UDPSocket.open do |s|
        s.connect(NAT_DISCOVERY_HOST, 8000)
        s.addr.last
      end
    ensure
      # restore DNS resolution
      Socket.do_not_reverse_lookup = orig_dnrl
    end
  end
end


client = MatchMaker::Client.new
nat_type = client.discover_nat_type
puts "NAT type: #{nat_type.inspect}"

exit(0)


    # In this case we should be able to send traffic from the src port I want
    # to receive a connection on to the matchmaker. The matchmaker would then
    # get my external port for that src port and tell the node I want to
    # connect to. The matchmaker would also tell my node what the external
    # port is for the node I want to connect to so that a connection can be
    # initiated.

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

# mm = MatchMaker.new
# if mm.register(node_id)
#   mm.connect(remote_node_id)
# end

