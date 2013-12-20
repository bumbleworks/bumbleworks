def wait_until(options = {}, &block)
  options[:timeout] ||= 5

  start_time = Time.now
  until block.call
    raise "The block never returned: \n#{block.to_source}" if (Time.now - start_time) > options[:timeout]
    sleep 0.1
  end
end
