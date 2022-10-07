# frozen_string_literal: true

require "warden"

module WardenOpenidBearer
  # Add this mixin to your `Warden::Strategies::Base` subclass to
  # streamline the `Warden::Strategies.add()` business.
  #
  # If you mix this into `Your::Class` (or inherit from one that
  # does, such as `OIDCBearer::Strategy`), then you can say
  #
  #   manager.default_strategies Your::Class.register!
  #
  module Registerer
    def self.included(klass)
      klass.extend(ClassMethods)
    end

    module ClassMethods
      def register!(as_symbol = default_registration_symbol)
        return @registered_symbol if @registered_symbol
        Warden::Strategies.add(as_symbol, self)
        @registered_symbol = as_symbol
      end

      protected

      def default_registration_symbol
        name.delete(":").sub(/Strategy$/, "").underscore.to_sym
      end
    end
  end
end
