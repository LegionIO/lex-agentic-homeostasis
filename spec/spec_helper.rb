# frozen_string_literal: true

require 'bundler/setup'

module Legion
  module Logging
    def self.debug(_msg); end
    def self.info(_msg); end
    def self.warn(_msg); end
    def self.error(_msg); end
    def self.fatal(_msg); end
  end

  module Extensions
    module Core
      def self.extended(_base); end
    end

    module Helpers
      module Lex
        def self.included(_base); end
      end
    end
  end
end

# rubocop:disable Lint/EmptyClass, Style/OneClassPerFile
module Legion
  module Extensions
    module Actors
      class Every; end
      class Once; end
    end
  end
end
$LOADED_FEATURES << 'legion/extensions/actors/every'
$LOADED_FEATURES << 'legion/extensions/actors/once'
# rubocop:enable Lint/EmptyClass, Style/OneClassPerFile

require 'legion/extensions/agentic/homeostasis'

RSpec.configure do |config|
  config.example_status_persistence_file_path = '.rspec_status'
  config.disable_monkey_patching!
  config.expect_with(:rspec) { |c| c.syntax = :expect }
end
