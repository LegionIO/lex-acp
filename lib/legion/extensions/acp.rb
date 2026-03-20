# frozen_string_literal: true

require_relative 'acp/version'
require_relative 'acp/helpers/protocol'

module Legion
  module Extensions
    module Acp
      extend Legion::Extensions::Core if Legion::Extensions.const_defined?(:Core)
    end
  end
end
