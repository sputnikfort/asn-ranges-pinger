# frozen_string_literal: true

require 'net/http'
require 'json'
require './ranges_getter'

class TwoIPRangesGetter < RangesGetter
  attr_reader :service_name

  def initialize
    super()
    @service_name = "2ip.io"
  end

  def get_data(asn)
    puts "Enter your 2ip.io token or press enter to use token from $TWOIP_TOKEN:"
    line = STDIN.gets
    token = line ? line.chomp : nil
    if token.nil? || token.empty?
      token = ENV["TWOIP_TOKEN"]
      unless token && !token.empty?
        abort "env token empty!"
      end
    end

    uri = URI("https://api.2ip.io/asn/#{asn}?token=#{token}")

    puts asn
    puts token

    response = Net::HTTP.get(uri)
    data = JSON.parse(response)

    prefixes = data["prefixes"] || []

    prefixes.map! { |ip| ip.sub(/\/\d+\z/, '') }

    prefixes.each do |p|
      puts p
    end
    prefixes
  end
end
