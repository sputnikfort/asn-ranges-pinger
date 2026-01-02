# frozen_string_literal: true

# require 'net/http'
# require 'json'
#
# asn = 200350
# token = "uw7tvchedkg8owvh"
#
# uri = URI("https://api.2ip.io/asn/#{asn}?token=#{token}")
#
# response = Net::HTTP.get(uri)
# puts response
# data = JSON.parse(response)
# puts data
# puts data["prefixes"] || []
#
def ranges_exists?(name = "ranges.json")
   File.exist?(name) && File.readable?(name)
end

puts ranges_exists?
