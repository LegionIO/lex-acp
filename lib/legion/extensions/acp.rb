# frozen_string_literal: true

require_relative 'acp/version'

module Legion
  module Extensions
    module Acp
      extend Legion::Extensions::Core if Legion::Extensions.const_defined?(:Core)
    end
  end
end
