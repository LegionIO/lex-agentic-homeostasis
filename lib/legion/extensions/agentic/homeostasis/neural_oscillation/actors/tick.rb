# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Homeostasis
        module NeuralOscillation
          module Actor
            class Tick < Legion::Extensions::Actors::Every
              def time
                5
              end

              def use_runner?
                false
              end

              def runner_function
                :update_neural_oscillations
              end

              def runner_class
                Legion::Extensions::Agentic::Homeostasis::NeuralOscillation::Runners::NeuralOscillation
              end
            end
          end
        end
      end
    end
  end
end
