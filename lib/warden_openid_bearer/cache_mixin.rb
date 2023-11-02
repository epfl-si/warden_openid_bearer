# frozen_string_literal: true

module WardenOpenidBearer
  # We don't need an overengineered approach based on the Rails cache.
  # No, really.
  module CacheMixin
    def cached_by(*keys, &do_it)
      @__cache_mixin__cache ||= {}

      caller_method = caller(1..1).first[/`.*'/][1..-2]
      keys.unshift(caller_method)

      first_keys = keys.slice!(0, keys.length - 1).join("|")
      last_key = keys[0]

      last_key_is_value_type = last_key.is_a? String
      cache = @__cache_mixin__cache[first_keys] ||= if last_key_is_value_type
                {}
              else
                # Use the ::ObjectSpace::WeakMap private API, because the
                # endeavor of reinventing weak maps on top of (public)
                # WeakRef's would be called an inversion of abstraction and
                # would be considered harmful. Sue me (I have unit tests).
                ::ObjectSpace::WeakMap.new
              end

      now = Time.now()

      if (cached = cache[last_key])
        unless respond_to?(:cache_timeout) && now - cached[:fetched_at] > cache_timeout
          return cached[:payload]
        end
      end

      retval = do_it.call
      cache[last_key] = {payload: retval, fetched_at: now}
      retval
    end
  end
end
