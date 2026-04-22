# frozen_string_literal: true

require 'legion/extensions/actors/every'

module Legion
  module Extensions
    module Agentic
      module Homeostasis
        module Homeostasis
          module Actor
            class Correct < Legion::Extensions::Actors::Every
              def runner_class
                Legion::Extensions::Agentic::Homeostasis::Homeostasis::Runners::CognitiveHomeostasis
              end

              def runner_function
                'update_cognitive_homeostasis'
              end

              def time
                30
              end

              def run_now?
                false
              end

              def use_runner?
                false
              end

              def check_subtask?
                false
              end

              def generate_task?
                false
              end
            end
          end
        end
      end
    end
  end
end
