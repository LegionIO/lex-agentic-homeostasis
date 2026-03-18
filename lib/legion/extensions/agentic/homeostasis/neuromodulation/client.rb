# frozen_string_literal: true

require 'legion/extensions/agentic/homeostasis/neuromodulation/helpers/constants'
require 'legion/extensions/agentic/homeostasis/neuromodulation/helpers/modulator'
require 'legion/extensions/agentic/homeostasis/neuromodulation/helpers/modulator_system'
require 'legion/extensions/agentic/homeostasis/neuromodulation/runners/neuromodulation'

module Legion
  module Extensions
    module Agentic
      module Homeostasis
        module Neuromodulation
          class Client
            include Runners::Neuromodulation

            def initialize(system: nil, **)
              @neuromod_system = system || Helpers::ModulatorSystem.new
            end

            private

            attr_reader :neuromod_system
          end
        end
      end
    end
  end
end
