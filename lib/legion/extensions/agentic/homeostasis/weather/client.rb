# frozen_string_literal: true

require 'legion/extensions/agentic/homeostasis/weather/helpers/constants'
require 'legion/extensions/agentic/homeostasis/weather/helpers/front'
require 'legion/extensions/agentic/homeostasis/weather/helpers/storm'
require 'legion/extensions/agentic/homeostasis/weather/helpers/weather_engine'
require 'legion/extensions/agentic/homeostasis/weather/runners/cognitive_weather'

module Legion
  module Extensions
    module Agentic
      module Homeostasis
        module Weather
          class Client
            include Runners::CognitiveWeather

            def initialize(**)
              @weather_engine = Helpers::WeatherEngine.new
            end

            private

            attr_reader :weather_engine
          end
        end
      end
    end
  end
end
