# frozen_string_literal: true

require 'json'
require 'open3'
require 'shellwords'

def start_ping
  available_ips = []

  begin
    content = File.read("ranges.json")
    ranges = JSON.parse(content)
  rescue Errno::ENOENT
    puts "Файл ranges.json не найден."
    return []
  rescue JSON::ParserError
    puts "Ошибка разбора ranges.json — неверный JSON."
    return []
  end

  unless ranges.is_a?(Array) && !ranges.empty?
    puts "ranges.json должен содержать массив IP-адресов."
    return []
  end

  ranges.each do |ip|
    next unless ip.is_a?(String) && ip.strip != ''

    print "Pinging #{ip}... "
    if icmp_ping_ok?(ip)
      puts "OK"
      available_ips << ip
    else
      puts "FAILED"
    end
  end

  if available_ips.empty?
    puts "No available IPs found."
  else
    puts "Available IPs:"
    available_ips.each { |ip| puts ip }
  end

  available_ips
end

def icmp_ping_ok?(ip, count = 1)
  escaped_ip = Shellwords.escape(ip.to_s)
  is_windows = Gem.win_platform?

  cmd =
    if is_windows
      "ping -n #{count} #{escaped_ip}"
    else
      "ping -c #{count} #{escaped_ip}"
    end

  stdout, stderr, status = Open3.capture3("#{cmd} 2>&1")

  # базовые шаблоны ошибок в выводе
  error_patterns = [
    /Destination Port Unreachable/i,
    /Destination Host Unreachable/i,
    /Network is unreachable/i,
    /General failure/i,
    /100% packet loss/i,
    /Request timed out/i
  ]

  return false unless status.success? == true || stdout.match?(/ttl=/i)

  error_patterns.each do |pattern|
    return false if stdout.match?(pattern) || stderr.match?(pattern)
  end

  true
end

