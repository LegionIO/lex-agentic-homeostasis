# frozen_string_literal: true

require 'legion/extensions/agentic/homeostasis/fatigue_model/helpers/constants'
require 'legion/extensions/agentic/homeostasis/fatigue_model/helpers/channel'
require 'legion/extensions/agentic/homeostasis/fatigue_model/helpers/fatigue_engine'
require 'legion/extensions/agentic/homeostasis/fatigue_model/runners/cognitive_fatigue_model'

module Legion
  module Extensions
    module Agentic
      module Homeostasis
        module FatigueModel
          class Client
            include Runners::CognitiveFatigueModel

            def initialize(**)
              @engine = Helpers::FatigueEngine.new
            end

            private

            attr_reader :engine
          end
        end
      end
    end
  end
end
