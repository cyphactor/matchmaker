
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
    @sessions[data] = {:client_ip => sender_ip, :client_port => sender_port}
    listener.send("register:successful", 0, sender_ip, sender_port)
  elsif action == "connect"
    if @sessions[data].nil?
      listener.send("connect:pending", 0, sender_ip, sender_port)
    else
      peer = @sessions[data]
      listener.send("connect:success:#{peer[:client_ip]}:#{peer[:client_port]}", 0, sender_ip, sender_port)
      listener.send("connect:success:#{sender_ip}:#{sender_port}", 0, peer[:client_ip], peer[:client_port])
    end
  end
  # punch.send('', 0, sender_ip, sender_port)
  puts "GOT MESSAGE FROM #{sender_ip} #{payload}"
  sleep 1
end

