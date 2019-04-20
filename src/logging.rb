require_relative 'constants.rb'

# wrapper module for logging
module Logging
	# method for general logging
	def self.log section, subsection, status, level = 1
		puts "[#{Time.new.inspect}: #{section}: #{subsection}] #{status}" if Constants::LOGGING_LEVELS.include? level
	end
end