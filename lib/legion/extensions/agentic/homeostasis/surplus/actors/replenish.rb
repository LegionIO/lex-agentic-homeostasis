# frozen_string_literal: true

require 'legion/extensions/actors/every'

module Legion
  module Extensions
    module Agentic
      module Homeostasis
        module Surplus
          module Actor
            class Replenish < Legion::Extensions::Actors::Every
              def runner_class
                Legion::Extensions::Agentic::Homeostasis::Surplus::Runners::Surplus
              end

              def runner_function
                'replenish_surplus'
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
