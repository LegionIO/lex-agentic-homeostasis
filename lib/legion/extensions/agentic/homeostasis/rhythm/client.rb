# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Homeostasis
        module Rhythm
          class Client
            include Runners::CognitiveRhythm

            def initialize(engine: nil)
              @engine = engine || Helpers::RhythmEngine.new
            end
          end
        end
      end
    end
  end
end
