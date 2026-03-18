# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Homeostasis
        module Homeostasis
          class Client
            include Runners::CognitiveHomeostasis

            def engine
              @engine ||= Helpers::HomeostasisEngine.new
            end
          end
        end
      end
    end
  end
end
