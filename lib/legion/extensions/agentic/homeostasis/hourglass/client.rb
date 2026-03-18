# frozen_string_literal: true

require 'legion/extensions/agentic/homeostasis/hourglass/helpers/constants'
require 'legion/extensions/agentic/homeostasis/hourglass/helpers/grain'
require 'legion/extensions/agentic/homeostasis/hourglass/helpers/hourglass'
require 'legion/extensions/agentic/homeostasis/hourglass/helpers/hourglass_engine'
require 'legion/extensions/agentic/homeostasis/hourglass/runners/cognitive_hourglass'

module Legion
  module Extensions
    module Agentic
      module Homeostasis
        module Hourglass
          class Client
            include Runners::CognitiveHourglass

            def initialize(**)
              @hourglass_engine = Helpers::HourglassEngine.new
            end

            private

            attr_reader :hourglass_engine
          end
        end
      end
    end
  end
end
