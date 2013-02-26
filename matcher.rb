
require 'socket'

punch = UDPSocket.new
punch.bind('', 6311)

listener = UDPSocket.new
listener.bind('0.0.0.0', 9523)

@sessions = {}

loop do
  payload, sender = listener.recvfrom(16)
  puts "#{sender.inspect}"
  sender_ip = sender[3]
  sender_port = sender[1]
  action, data = payload.split(":") 
  if action == "register"
    if sender_port == "8341"
      @randomized = false
    else
      @randomized = true
    end
    @sessions[data] = {:client_ip => sender_ip, :client_port => sender_port, :randomized => @randomized}
    listener.send("register:successful", 0, sender_ip, sender_port)
  elsif action == "connect"
    if @sessions[data].nil?
      listener.send("connect:pending", 0, sender_ip, sender_port)
    else
      peer = @sessions[data]
      if peer[:randomized]
        listener.send("connect:success:#{peer[:client_ip]}:#{peer[:client_port]},initiator", 0, sender_ip, sender_port)
        listener.send("connect:success:#{sender_ip}:#{sender_port},listen", 0, peer[:client_ip], peer[:client_port])
      else
        listener.send("connect:success:#{peer[:client_ip]}:#{peer[:client_port]},listen", 0, sender_ip, sender_port)
        listener.send("connect:success:#{sender_ip}:#{sender_port},initiator", 0, peer[:client_ip], peer[:client_port])
      end
    end
  end
  # punch.send('', 0, sender_ip, sender_port)
  puts "GOT MESSAGE FROM #{sender_ip} #{payload}"
  sleep 1
end
