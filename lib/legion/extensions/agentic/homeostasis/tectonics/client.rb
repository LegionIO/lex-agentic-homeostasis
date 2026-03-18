# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Homeostasis
        module Tectonics
          class Client
            include Runners::CognitiveTectonics

            attr_reader :engine

            def initialize(engine: nil, **)
              @engine          = engine || Helpers::TectonicEngine.new
              @tectonic_engine = @engine
            end
          end
        end
      end
    end
  end
end
