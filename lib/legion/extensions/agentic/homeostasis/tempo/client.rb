# frozen_string_literal: true

require 'legion/extensions/agentic/homeostasis/tempo/helpers/constants'
require 'legion/extensions/agentic/homeostasis/tempo/helpers/tempo_record'
require 'legion/extensions/agentic/homeostasis/tempo/helpers/tempo_engine'
require 'legion/extensions/agentic/homeostasis/tempo/runners/tempo'

module Legion
  module Extensions
    module Agentic
      module Homeostasis
        module Tempo
          class Client
            include Runners::Tempo

            def initialize(**)
              @tempo_engine = Helpers::TempoEngine.new
            end

            private

            attr_reader :tempo_engine
          end
        end
      end
    end
  end
end
