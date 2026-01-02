# frozen_string_literal: true

require 'json'
require './twoip_ranges_getter'
require './ranges_getter'

def ranges_exists?(name = "ranges.json")
  File.exist?(name) && File.readable?(name)
end

def ranges_filled?(name = "ranges.json")
  return false unless ranges_exists?(name)
  begin
    ips = JSON.parse(File.read(name))
  rescue JSON::ParserError
    return false
  end

  return false unless ips.is_a?(Array) && !ips.empty?

  ip_like = /\b(?:\d{1,3}\.){3}\d{1,3}\b/

  ips.all? { |ip| ip.is_a?(String) && ip.match?(ip_like) }
end

# @param getter [RangesGetter] method of getting ranges
# @param asn [Integer] asn number
def get_ranges(getter, asn)

  unless getter.is_a?(RangesGetter)
    raise ArgumentError, "getter must implement RangesGetter!"
  end

  ranges = getter.get_data(asn)

  if ranges.nil? || !ranges.is_a?(Array) || ranges.empty?
    puts "no ranges received!"
    return
  end

  ranges.each do |range|
    puts range
  end

  if ranges_exists?
    FileUtils.mv("ranges.json", "ranges_old_#{Time.now.strftime('%H-%M-%S_%d.%m.%Y')}.json")
    FileUtils.touch("ranges.json")
  end

  File.open("ranges.json", "w") do |f|
    f.write(JSON.pretty_generate(ranges))
  end
end

def ranges_chose
  puts "enter the actual asn or press enter to use last known one (Yandex Cloud ASN 200350):"
  line = STDIN.gets&.chomp

  if line.nil? || line.empty? || !(line =~ /^\d+$/)
    asn = 200350
  else
    asn = line.to_i
  end

  puts "using asn: #{asn}"

  range_getter_services = [TwoIPRangesGetter.new]

  valid_services = range_getter_services.select { |s| s.is_a?(RangesGetter) }

  if valid_services.empty?
    puts "no available services!"
    return nil
  end

  puts "choose the service to get ranges from:"

  valid_services.each_with_index do |service, index|
    puts "#{index + 1} - #{service.service_name}"
  end

  puts "0 - back to main menu"

  line = STDIN.gets&.chomp
  return nil if line.nil?

  unless line =~ /^\d+$/
    puts "unknown choice: #{line}"
    return nil
  end

  choice = line.to_i

  if choice == 0
    return nil
  end

  unless choice.between?(1, valid_services.length)
    puts "unknown choice: #{choice}"
    return nil
  end

  get_ranges(valid_services[choice - 1], asn)
end

