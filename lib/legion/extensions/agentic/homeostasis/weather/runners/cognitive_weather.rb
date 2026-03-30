# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Homeostasis
        module Weather
          module Runners
            module CognitiveWeather
              extend self

              include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers, false) &&
                                                          Legion::Extensions::Helpers.const_defined?(:Lex, false)

              def create_front(front_type: :warm, domain: 'default', pressure: 0.5,
                               temperature: 0.5, humidity: 0.5, engine: nil, **)
                eng   = engine || weather_engine
                front = eng.create_front(
                  front_type:  front_type.to_sym,
                  domain:      domain,
                  pressure:    pressure.to_f,
                  temperature: temperature.to_f,
                  humidity:    humidity.to_f
                )
                if front
                  log.debug("[cognitive_weather] front created: type=#{front_type} " \
                            "domain=#{domain} pressure=#{pressure}")
                  { success: true, front: front.to_h }
                else
                  log.warn('[cognitive_weather] create_front: MAX_FRONTS reached')
                  { success: false, reason: :max_fronts_reached }
                end
              rescue ArgumentError => e
                log.error("[cognitive_weather] create_front failed: #{e.message}")
                { success: false, error: e.message }
              end

              def brew_storm(front_id:, condition: :stormy, intensity: 0.5, coverage: 0.5, engine: nil, **)
                eng   = engine || weather_engine
                storm = eng.brew_storm(
                  front_id:  front_id.to_s,
                  condition: condition.to_sym,
                  intensity: intensity.to_f,
                  coverage:  coverage.to_f
                )
                if storm
                  log.debug("[cognitive_weather] storm brewed: condition=#{condition} " \
                            "intensity=#{intensity} front=#{front_id}")
                  { success: true, storm: storm.to_h }
                else
                  log.warn('[cognitive_weather] brew_storm: front not found or MAX_STORMS reached')
                  { success: false, reason: :brew_failed }
                end
              rescue ArgumentError => e
                log.error("[cognitive_weather] brew_storm failed: #{e.message}")
                { success: false, error: e.message }
              end

              def intensify(storm_id:, rate: Helpers::Constants::PRESSURE_CHANGE_RATE, engine: nil, **)
                eng   = engine || weather_engine
                storm = eng.intensify_storm(storm_id: storm_id.to_s, rate: rate.to_f)
                if storm
                  log.debug("[cognitive_weather] storm intensified: id=#{storm_id} " \
                            "intensity=#{storm.intensity.round(3)} raging=#{storm.raging?}")
                  { success: true, storm: storm.to_h }
                else
                  log.warn("[cognitive_weather] intensify: storm #{storm_id} not found")
                  { success: false, reason: :storm_not_found }
                end
              rescue ArgumentError => e
                log.error("[cognitive_weather] intensify failed: #{e.message}")
                { success: false, error: e.message }
              end

              def forecast(engine: nil, **)
                eng      = engine || weather_engine
                forecast = eng.weather_forecast
                log.debug("[cognitive_weather] forecast: condition=#{forecast[:condition]} " \
                          "avg_intensity=#{forecast[:avg_intensity]&.round(3)} " \
                          "storms=#{forecast[:active_storms]}")
                forecast.merge(success: true)
              rescue ArgumentError => e
                log.error("[cognitive_weather] forecast failed: #{e.message}")
                { success: false, error: e.message }
              end

              def list_fronts(engine: nil, **)
                eng = engine || weather_engine
                fronts = eng.fronts.map(&:to_h)
                log.debug("[cognitive_weather] list_fronts: count=#{fronts.size}")
                { success: true, fronts: fronts, count: fronts.size }
              rescue ArgumentError => e
                log.error("[cognitive_weather] list_fronts failed: #{e.message}")
                { success: false, error: e.message }
              end

              def weather_status(engine: nil, **)
                eng    = engine || weather_engine
                report = eng.atmospheric_report
                log.debug("[cognitive_weather] weather_status: fronts=#{report[:front_count]} " \
                          "storms=#{report[:storm_count]}")
                report.merge(success: true)
              rescue ArgumentError => e
                log.error("[cognitive_weather] weather_status failed: #{e.message}")
                { success: false, error: e.message }
              end

              private

              def weather_engine
                @weather_engine ||= Helpers::WeatherEngine.new
              end
            end
          end
        end
      end
    end
  end
end
