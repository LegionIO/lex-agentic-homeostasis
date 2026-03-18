# frozen_string_literal: true

require 'legion/extensions/agentic/homeostasis/surplus/helpers/constants'
require 'legion/extensions/agentic/homeostasis/surplus/helpers/allocation'
require 'legion/extensions/agentic/homeostasis/surplus/helpers/surplus_engine'
require 'legion/extensions/agentic/homeostasis/surplus/runners/surplus'

module Legion
  module Extensions
    module Agentic
      module Homeostasis
        module Surplus
          class Client
            include Runners::Surplus

            def initialize(**)
              @surplus_engine = Helpers::SurplusEngine.new
            end

            private

            attr_reader :surplus_engine
          end
        end
      end
    end
  end
end
