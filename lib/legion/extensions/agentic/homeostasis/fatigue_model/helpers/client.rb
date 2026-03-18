# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Homeostasis
        module FatigueModel
          module Helpers
            class Client
              include Runners::CognitiveFatigueModel

              def initialize(**)
                @engine = Helpers::FatigueEngine.new
              end

              private

              attr_reader :engine
            end
          end
        end
      end
    end
  end
end
