# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Homeostasis
        module Weather
          module Helpers
            class WeatherEngine
              attr_reader :fronts, :storms

              def initialize
                @fronts = []
                @storms = []
              end

              # Create a new atmospheric front; respects MAX_FRONTS
              def create_front(front_type:, domain:, pressure: 0.5, temperature: 0.5, humidity: 0.5)
                return nil if @fronts.size >= Constants::MAX_FRONTS

                front = Front.new(
                  front_type:  front_type,
                  domain:      domain,
                  pressure:    pressure,
                  temperature: temperature,
                  humidity:    humidity
                )
                @fronts << front
                front
              end

              # Brew a storm anchored to a front; respects MAX_STORMS
              def brew_storm(front_id:, condition: :stormy, intensity: 0.5, coverage: 0.5)
                return nil if @storms.size >= Constants::MAX_STORMS
                return nil unless find_front(front_id)

                storm = Storm.new(
                  condition: condition,
                  front_ids: [front_id],
                  intensity: intensity,
                  coverage:  coverage
                )
                @storms << storm
                storm
              end

              # Intensify a storm by id
              def intensify_storm(storm_id:, rate: Constants::PRESSURE_CHANGE_RATE)
                storm = find_storm(storm_id)
                return nil unless storm

                storm.intensify!(rate)
                storm
              end

              # Dissipate all storms by one cycle
              def dissipate_all!(rate = Constants::DISSIPATION_RATE)
                @storms.each { |s| s.dissipate!(rate) }
                @storms.size
              end

              # Current conditions summary: dominant condition, average intensity, active storm count
              def weather_forecast
                if @storms.empty?
                  return {
                    condition:      :clear,
                    avg_intensity:  0.0,
                    active_storms:  0,
                    dominant_front: nil,
                    clarity_label:  'crystal',
                    severity_label: 'calm'
                  }
                end

                avg_intensity  = @storms.sum(&:intensity) / @storms.size.to_f
                dominant_storm = @storms.max_by(&:intensity)
                dominant_front = most_severe

                {
                  condition:      dominant_storm.condition,
                  avg_intensity:  avg_intensity.round(10),
                  active_storms:  @storms.size,
                  dominant_front: dominant_front&.to_h,
                  clarity_label:  dominant_storm.clarity_label,
                  severity_label: dominant_front ? dominant_front.severity_label : 'calm'
                }
              end

              # Front with highest pressure
              def most_severe
                return nil if @fronts.empty?

                @fronts.max_by(&:pressure)
              end

              # Front with lowest pressure
              def calmest
                return nil if @fronts.empty?

                @fronts.min_by(&:pressure)
              end

              # Full atmospheric report
              def atmospheric_report
                {
                  front_count: @fronts.size,
                  storm_count: @storms.size,
                  fronts:      @fronts.map(&:to_h),
                  storms:      @storms.map(&:to_h),
                  forecast:    weather_forecast,
                  most_severe: most_severe&.to_h,
                  calmest:     calmest&.to_h
                }
              end

              private

              def find_front(front_id)
                @fronts.find { |f| f.id == front_id.to_s }
              end

              def find_storm(storm_id)
                @storms.find { |s| s.id == storm_id.to_s }
              end
            end
          end
        end
      end
    end
  end
end
