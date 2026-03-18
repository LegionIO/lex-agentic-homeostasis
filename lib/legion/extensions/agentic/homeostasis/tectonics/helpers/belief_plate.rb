# frozen_string_literal: true

require 'securerandom'

module Legion
  module Extensions
    module Agentic
      module Homeostasis
        module Tectonics
          module Helpers
            class BeliefPlate
              include Constants

              attr_reader :id, :domain, :content, :created_at, :state
              attr_accessor :mass, :drift_vector, :position, :velocity, :stress_accumulation

              def initialize(domain:, content:, mass: 0.5, drift_vector: nil, position: nil, **)
                @id                  = SecureRandom.uuid
                @domain              = domain
                @content             = content
                @mass                = mass.clamp(0.0, 1.0)
                @drift_vector        = drift_vector || { x: 0.0, y: 0.0 }
                @position            = position || { x: rand(-10.0..10.0).round(10), y: rand(-10.0..10.0).round(10) }
                @velocity            = { x: 0.0, y: 0.0 }
                @stress_accumulation = 0.0
                @state               = :active
                @created_at          = Time.now.utc
              end

              def drift!(delta_t = 1.0)
                return if @state != :active

                @position[:x] = (@position[:x] + (@drift_vector.fetch(:x, 0.0) * delta_t)).round(10)
                @position[:y] = (@position[:y] + (@drift_vector.fetch(:y, 0.0) * delta_t)).round(10)
              end

              def accumulate_stress!(amount)
                @stress_accumulation = (@stress_accumulation + amount.abs).round(10)
              end

              def release_stress!
                released = @stress_accumulation
                @stress_accumulation = 0.0
                released
              end

              def subducted?
                @mass < Constants::SUBDUCTION_RATIO
              end

              def subduct!
                @state = :subducted
              end

              def dormant!
                @state = :dormant
              end

              def active?
                @state == :active
              end

              def distance_to(other_plate)
                dx = @position[:x] - other_plate.position[:x]
                dy = @position[:y] - other_plate.position[:y]
                Math.sqrt((dx**2) + (dy**2)).round(10)
              end

              def to_h
                {
                  id:                  @id,
                  domain:              @domain,
                  content:             @content,
                  mass:                @mass,
                  drift_vector:        @drift_vector,
                  position:            @position,
                  velocity:            @velocity,
                  stress_accumulation: @stress_accumulation,
                  state:               @state,
                  created_at:          @created_at
                }
              end
            end
          end
        end
      end
    end
  end
end
