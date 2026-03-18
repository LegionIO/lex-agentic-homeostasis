# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Homeostasis
        module Temporal
          class Client
            include Runners::Temporal

            attr_reader :temporal_store

            def initialize(temporal_store: nil, **)
              @temporal_store = temporal_store || Helpers::TemporalStore.new
            end
          end
        end
      end
    end
  end
end
