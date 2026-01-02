# frozen_string_literal: true

require 'json'
require 'open3'
require 'shellwords'
require 'timeout'

def start_ping
  available_ips = []

  begin
    content = File.read("ranges.json")
    ranges = JSON.parse(content)
  rescue Errno::ENOENT
    puts "File ranges.json not found."
    return []
  rescue JSON::ParserError
    puts "Failed to parse ranges.json — invalid JSON."
    return []
  end

  unless ranges.is_a?(Array) && !ranges.empty?
    puts "ranges.json must contain an array of IP addresses."
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

  begin
    out = ''
    status = nil
    Open3.popen3("#{cmd} 2>&1") do |_stdin, stdout, _stderr, wait_thr|
      out_reader = Thread.new { stdout.read }

      begin
        # if the check takes longer than 2 seconds — consider the IP acceptable
        Timeout.timeout(2) do
          status = wait_thr.value
        end
        out = out_reader.value
      rescue Timeout::Error
        # timeout exceeded — terminate the process and consider the IP acceptable
        begin
          Process.kill('TERM', wait_thr.pid) rescue nil
          sleep 0.1
          Process.kill('KILL', wait_thr.pid) rescue nil
        rescue StandardError
          # noop
        ensure
          out = out_reader.value rescue ''
        end
        return true
      ensure
        out_reader.kill if out_reader.alive?
      end
    end
  rescue StandardError
    # on unexpected errors — do not consider the address acceptable
    return false
  end

  # after a fast check: consider the address acceptable if there is ttl or the process exited successfully
  return true if out.match?(/ttl=/i)
  return true if status&.success?

  false
end
