# frozen_string_literal: true

require 'legion/extensions/agentic/homeostasis/tide/helpers/constants'
require 'legion/extensions/agentic/homeostasis/tide/helpers/oscillator'
require 'legion/extensions/agentic/homeostasis/tide/helpers/tidal_pool'
require 'legion/extensions/agentic/homeostasis/tide/helpers/tide_engine'
require 'legion/extensions/agentic/homeostasis/tide/runners/cognitive_tide'

module Legion
  module Extensions
    module Agentic
      module Homeostasis
        module Tide
          class Client
            include Runners::CognitiveTide

            def initialize(**)
              @tide_engine = Helpers::TideEngine.new
            end

            private

            attr_reader :tide_engine
          end
        end
      end
    end
  end
end
