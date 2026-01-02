# frozen_string_literal: true
#!/usr/bin/env ruby

require './ranges'
require './ping'

while true
  puts "What do you want to do?"
  puts "1 - get ranges of ip for yandex cloud asn (#{ranges_filled? ? 'filled' : 'not filled'})"
  puts "2 - check available ip ranges by ping"
  puts "0 - exit"

  line = STDIN.gets
  choice = line ? line.chomp : nil

  case choice
  when "1"
    ranges_chose
  when "2"
    if ranges_filled?
      start_ping
    else
      puts "ranges not filled yet, please get ranges first"
    end
  when "0"
    puts "bye!"
    exit
  else
    puts "unknown choice: #{choice}"
  end
end
