# frozen_string_literal: true


class RangesGetter
  attr_reader :service_name

  def initialize
    @service_name = "undefined service name"
  end

  # @param asn [Integer] asn number
  # @return [Array<String>] array of IP ranges
  def get_data(asn)
    raise NotImplementedError, "Method 'get_data' must be implemented in subclass!"
  end

end
