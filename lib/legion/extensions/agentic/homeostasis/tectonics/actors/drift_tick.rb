# frozen_string_literal: true

require 'legion/extensions/actors/every'

module Legion
  module Extensions
    module Agentic
      module Homeostasis
        module Tectonics
          module Actor
            class DriftTick < Legion::Extensions::Actors::Every
              def runner_class
                Legion::Extensions::Agentic::Homeostasis::Tectonics::Runners::CognitiveTectonics
              end

              def runner_function
                'drift_tick'
              end

              def time
                60
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
