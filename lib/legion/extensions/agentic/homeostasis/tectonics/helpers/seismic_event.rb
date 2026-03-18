# frozen_string_literal: true

require 'securerandom'

module Legion
  module Extensions
    module Agentic
      module Homeostasis
        module Tectonics
          module Helpers
            class SeismicEvent
              include Constants

              EVENT_TYPES = %i[earthquake tremor aftershock].freeze

              attr_reader :id, :type, :magnitude, :epicenter_plate_id,
                          :affected_plate_ids, :timestamp, :parent_event_id

              def initialize(type:, magnitude:, epicenter_plate_id:, affected_plate_ids: [], parent_event_id: nil, **)
                raise ArgumentError, "unknown event type: #{type.inspect}" unless EVENT_TYPES.include?(type)

                @id                 = SecureRandom.uuid
                @type               = type
                @magnitude          = magnitude.clamp(0.0, Float::INFINITY)
                @epicenter_plate_id = epicenter_plate_id
                @affected_plate_ids = Array(affected_plate_ids)
                @parent_event_id    = parent_event_id
                @timestamp          = Time.now.utc
              end

              def aftershock?
                @type == :aftershock
              end

              def label
                label_for(@magnitude)
              end

              def to_h
                {
                  id:                 @id,
                  type:               @type,
                  magnitude:          @magnitude,
                  label:              label,
                  epicenter_plate_id: @epicenter_plate_id,
                  affected_plate_ids: @affected_plate_ids,
                  parent_event_id:    @parent_event_id,
                  timestamp:          @timestamp
                }
              end
            end
          end
        end
      end
    end
  end
end
