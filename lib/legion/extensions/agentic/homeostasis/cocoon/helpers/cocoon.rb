# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Homeostasis
        module Cocoon
          module Helpers
            class Cocoon
              include Constants

              attr_reader :id, :cocoon_type, :domain, :content, :maturity,
                          :stage, :protection, :created_at

              def initialize(cocoon_type:, domain:, content: '', maturity: nil, protection: nil)
                @id = SecureRandom.uuid
                @cocoon_type = cocoon_type.to_sym
                @domain     = domain.to_sym
                @content    = content
                @maturity   = (maturity || 0.0).to_f.clamp(0.0, 1.0)
                @protection = (protection || PROTECTION_BY_TYPE.fetch(@cocoon_type, 0.7)).to_f.clamp(0.0, 1.0)
                @stage      = :encapsulating
                @created_at = Time.now.utc
                advance_stage!
              end

              def gestate!(rate = MATURITY_RATE)
                return self if @stage == :emerged

                @maturity = (@maturity + rate).clamp(0.0, 1.0).round(10)
                advance_stage!
                self
              end

              def emerge!
                return { success: false, error: 'not ready', damaged: false } unless ready?

                @stage = :emerged
                { success: true, content: @content, damaged: false, maturity: @maturity }
              end

              def expose!
                damaged = premature?
                @maturity = (@maturity * PREMATURE_PENALTY).round(10) if damaged
                @stage = :emerged
                { success: true, content: @content, damaged: damaged, maturity: @maturity }
              end

              def ready?
                @maturity >= 1.0 || @stage == :ready
              end

              def premature?
                @stage != :ready && @stage != :emerged && @maturity < 1.0
              end

              def age_seconds
                (Time.now.utc - @created_at).round(2)
              end

              def to_h
                {
                  id:             @id,
                  cocoon_type:    @cocoon_type,
                  domain:         @domain,
                  content:        @content,
                  maturity:       @maturity.round(10),
                  stage:          @stage,
                  protection:     @protection.round(10),
                  ready:          ready?,
                  premature:      premature?,
                  maturity_label: Constants.label_for(MATURITY_LABELS, @maturity),
                  age_seconds:    age_seconds,
                  created_at:     @created_at.iso8601
                }
              end

              private

              def advance_stage!
                @stage = compute_stage
              end

              def compute_stage
                return :emerged if @stage == :emerged

                if @maturity >= 1.0
                  :ready
                elsif @maturity >= 0.75
                  :transforming
                elsif @maturity >= 0.4
                  :developing
                else
                  :encapsulating
                end
              end
            end
          end
        end
      end
    end
  end
end
