# frozen_string_literal: true

require 'securerandom'

require_relative 'cocoon/version'
require_relative 'cocoon/helpers/constants'
require_relative 'cocoon/helpers/cocoon'
require_relative 'cocoon/helpers/incubator'
require_relative 'cocoon/runners/cognitive_cocoon'
require_relative 'cocoon/client'

module Legion
  module Extensions
    module Agentic
      module Homeostasis
        module Cocoon
        end
      end
    end
  end
end

Legion::Extensions.extend(Legion::Extensions::Core) if Legion::Extensions.const_defined?(:Core, false)
