# frozen_string_literal: true

module WardenOpenidBearer
  # We don't need an overengineered approach based on the Rails cache.
  # No, really.
  module CacheMixin
    def cached_by(key, &do_it)
      # We could support more complex types (e.g. arrays) as
      # value-type cache keys; but right now, our use cases don't
      # require it:
      is_value_type = key.is_a? String
      cache = if is_value_type
        @__cache_mixin__cache ||= {}
      else
        # Use the ::ObjectSpace::WeakMap private API, because the
        # endeavor of reinventing weak maps on top of (public)
        # WeakRef's would be called an inversion of abstraction and
        # would be considered harmful. Sue me (I have unit tests).
        @__cache_mixin__weakmap_cache ||= ::ObjectSpace::WeakMap.new
      end

      now = Time.now()

      if (cached = cache[key])
        unless respond_to?(:cache_timeout) && now - cached[:fetched_at] > cache_timeout
          return cached[:payload]
        end
      end

      retval = do_it.call
      cache[key] = {payload: retval, fetched_at: now}
      retval
    end
  end
end
