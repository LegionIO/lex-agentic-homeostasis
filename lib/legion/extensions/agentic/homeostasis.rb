# frozen_string_literal: true

require_relative 'homeostasis/version'
require_relative 'homeostasis/homeostasis'
require_relative 'homeostasis/fatigue_model'
require_relative 'homeostasis/metabolism'
require_relative 'homeostasis/rhythm'
require_relative 'homeostasis/tempo'
require_relative 'homeostasis/tide'
require_relative 'homeostasis/weathering'
require_relative 'homeostasis/weather'
require_relative 'homeostasis/pendulum'
require_relative 'homeostasis/cocoon'
require_relative 'homeostasis/fossil_fuel'
require_relative 'homeostasis/hourglass'
require_relative 'homeostasis/core'
require_relative 'homeostasis/neuromodulation'
require_relative 'homeostasis/neural_oscillation'
require_relative 'homeostasis/temporal'
require_relative 'homeostasis/temporal_discounting'
require_relative 'homeostasis/surplus'
require_relative 'homeostasis/tectonics'
require_relative 'homeostasis/furnace'

module Legion
  module Extensions
    module Agentic
      module Homeostasis
        extend Legion::Extensions::Core if Legion::Extensions.const_defined? :Core

        def self.remote_invocable?
          false
        end
      end
    end
  end
end
