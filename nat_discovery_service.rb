#!/usr/bin/env ruby

require 'socket'

t1 = Thread.new do
  listen_port = 9524
  listener = UDPSocket.new
  listener.bind('0.0.0.0', listen_port)
  puts "Bound to #{listen_port}"
  loop do
    puts "Waiting for message on port #{listen_port}"
    payload, sender = listener.recvfrom(32)
    puts "#{sender.inspect}"
    sender_ip = sender[3]
    sender_port = sender[1]

    listener.send("#{sender_ip}:#{sender_port}", 0, sender_ip, sender_port)

    puts "GOT MESSAGE on port #{listen_port} FROM #{sender_ip}:#{sender_port} - #{payload}"
  end
end

t2 = Thread.new do
  listen_port = 9525
  listener = UDPSocket.new
  listener.bind('0.0.0.0', listen_port)
  puts "Bound to #{listen_port}"
  loop do
    puts "Waiting for message on port #{listen_port}"
    payload, sender = listener.recvfrom(32)
    puts "#{sender.inspect}"
    sender_ip = sender[3]
    sender_port = sender[1]

    listener.send("#{sender_ip}:#{sender_port}", 0, sender_ip, sender_port)

    puts "GOT MESSAGE on port #{listen_port} FROM #{sender_ip}:#{sender_port} - #{payload}"
  end
end

t1.join
t2.join
