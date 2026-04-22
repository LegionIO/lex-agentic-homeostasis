# frozen_string_literal: true

require 'legion/extensions/actors/every'

module Legion
  module Extensions
    module Agentic
      module Homeostasis
        module Metabolism
          module Actor
            class Cycle < Legion::Extensions::Actors::Every
              def runner_class
                Legion::Extensions::Agentic::Homeostasis::Metabolism::Runners::CognitiveMetabolism
              end

              def runner_function
                'run_all_cycles'
              end

              def time
                120
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
