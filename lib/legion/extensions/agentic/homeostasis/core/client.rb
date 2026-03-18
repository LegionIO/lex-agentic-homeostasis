# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Homeostasis
        module Core
          class Client
            include Runners::Homeostasis

            attr_reader :regulator, :allostatic_load

            def initialize(regulator: nil, allostatic_load: nil, **)
              @regulator = regulator || Helpers::Regulator.new
              @allostatic_load = allostatic_load || Helpers::AllostaticLoad.new
            end
          end
        end
      end
    end
  end
end
