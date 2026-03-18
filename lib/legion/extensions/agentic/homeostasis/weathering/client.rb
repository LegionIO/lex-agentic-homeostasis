# frozen_string_literal: true

require 'legion/extensions/agentic/homeostasis/weathering/helpers/constants'
require 'legion/extensions/agentic/homeostasis/weathering/helpers/stressor'
require 'legion/extensions/agentic/homeostasis/weathering/helpers/weathering_engine'
require 'legion/extensions/agentic/homeostasis/weathering/runners/cognitive_weathering'

module Legion
  module Extensions
    module Agentic
      module Homeostasis
        module Weathering
          class Client
            include Runners::CognitiveWeathering

            def initialize(**)
              @weathering_engine = Helpers::WeatheringEngine.new
            end
          end
        end
      end
    end
  end
end
