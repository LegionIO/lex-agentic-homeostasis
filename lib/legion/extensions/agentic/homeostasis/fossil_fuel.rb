# frozen_string_literal: true

require 'securerandom'

require_relative 'fossil_fuel/version'
require_relative 'fossil_fuel/helpers/constants'
require_relative 'fossil_fuel/helpers/reserve'
require_relative 'fossil_fuel/helpers/combustion'
require_relative 'fossil_fuel/helpers/fuel_engine'
require_relative 'fossil_fuel/runners/cognitive_fossil_fuel'
require_relative 'fossil_fuel/client'

module Legion
  module Extensions
    module Agentic
      module Homeostasis
        module FossilFuel
        end
      end
    end
  end
end
