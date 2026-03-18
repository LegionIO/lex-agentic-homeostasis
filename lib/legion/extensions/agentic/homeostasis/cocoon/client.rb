# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Homeostasis
        module Cocoon
          class Client
            include Runners::CognitiveCocoon

            def initialize
              @default_engine = Helpers::Incubator.new
            end
          end
        end
      end
    end
  end
end
