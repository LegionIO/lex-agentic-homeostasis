# frozen_string_literal: true

require 'legion/extensions/agentic/homeostasis/furnace/helpers/constants'
require 'legion/extensions/agentic/homeostasis/furnace/helpers/ore'
require 'legion/extensions/agentic/homeostasis/furnace/helpers/crucible'
require 'legion/extensions/agentic/homeostasis/furnace/helpers/furnace_engine'
require 'legion/extensions/agentic/homeostasis/furnace/runners/cognitive_furnace'

module Legion
  module Extensions
    module Agentic
      module Homeostasis
        module Furnace
          class Client
            include Runners::CognitiveFurnace

            def initialize(**)
              @default_engine = Helpers::FurnaceEngine.new
            end

            def engine
              @default_engine
            end

            private

            attr_reader :default_engine
          end
        end
      end
    end
  end
end
