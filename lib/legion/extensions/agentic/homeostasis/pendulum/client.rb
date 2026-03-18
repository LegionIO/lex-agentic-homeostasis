# frozen_string_literal: true

require 'legion/extensions/agentic/homeostasis/pendulum/helpers/constants'
require 'legion/extensions/agentic/homeostasis/pendulum/helpers/pendulum'
require 'legion/extensions/agentic/homeostasis/pendulum/helpers/pendulum_engine'
require 'legion/extensions/agentic/homeostasis/pendulum/runners/cognitive_pendulum'

module Legion
  module Extensions
    module Agentic
      module Homeostasis
        module Pendulum
          class Client
            include Runners::CognitivePendulum

            def initialize(**)
              @pendulum_engine = Helpers::PendulumEngine.new
            end

            private

            attr_reader :pendulum_engine
          end
        end
      end
    end
  end
end
