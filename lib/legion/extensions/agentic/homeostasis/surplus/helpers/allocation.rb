# frozen_string_literal: true

require 'securerandom'

module Legion
  module Extensions
    module Agentic
      module Homeostasis
        module Surplus
          module Helpers
            class Allocation
              attr_reader :id, :activity_type, :amount, :quality, :created_at

              def initialize(activity_type:, amount:, quality:)
                @id            = SecureRandom.uuid
                @activity_type = activity_type
                @amount        = amount.round(10)
                @quality       = quality.round(10)
                @created_at    = Time.now.utc
                @released      = false
              end

              def release!
                @released = true
              end

              def active?
                !@released
              end

              def to_h
                {
                  id:            @id,
                  activity_type: @activity_type,
                  amount:        @amount,
                  quality:       @quality,
                  active:        active?,
                  created_at:    @created_at
                }
              end
            end
          end
        end
      end
    end
  end
end
