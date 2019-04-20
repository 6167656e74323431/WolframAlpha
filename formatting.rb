require 'discordrb'
require 'wolfram-alpha'

require_relative 'tables.rb'

# module to contain all formatting data
module WolframAlphaQueryFormatting
	# colour used for responses
	ANSWER_COLOUR = 0xffff00
	#colour used for error messages
	ERROR_COLOUR = 0xff0000

	# function to choose which formatting method needs to be used
	def self.format query, original_input
		return self.errorEmbed query, "Something went very, very wrong", original_input if query == nil
		return self.resultEmbed query if query.find {|pod| pod.title == "Result"} != nil
		return self.resultsEmbed query if query.find {|pod| pod.title == "Results"} != nil
		return self.nonResultEmbed query, original_input
	end

	# adds the input interpretation or the original input to an embed
	def self.addInputInterpretation query = nil, embed = nil, original_input = nil
		return nil if embed == nil or query == nil
		input_interpretation = query["Input"]
		if input_interpretation == nil then
			embed.add_field name: "Original Query", value: original_input
			return nil
		end
		embed.add_field name: input_interpretation.title, value: input_interpretation.subpods[0].plaintext
	end

	# creates an error enmbed for unsupported operations
	def self.errorEmbed query = nil, message = "", original_input = nil
		response = Discordrb::Webhooks::Embed.new color: ERROR_COLOUR
		self.addInputInterpretation query, response, original_input
		response.add_field name: "Error", value: message
		return response
	end

	# creates an embed if there is a result pod
	def self.resultEmbed query
		response = Discordrb::Webhooks::Embed.new color: ANSWER_COLOUR

		self.addInputInterpretation query, response

		result = query.find {|pod| pod.title == "Result"}
		return self.errorEmbed query, "This type of query is not currently supported" if result.subpods[0].plaintext == ""
		response.add_field name: result.title, value: result.subpods[0].plaintext.toTableIfNecessary

		return response
	end

	# creates an embed if there is a results pod
	def self.resultsEmbed query
		response = Discordrb::Webhooks::Embed.new color: ANSWER_COLOUR

		self.addInputInterpretation query, response

		result = query.find {|pod| pod.title == "Results"}
		result_text = ""
		result.subpods.each do |subpod|
			result_text << subpod.plaintext + "\n"
		end
		response.add_field name: result.title, value: result_text.toTableIfNecessary

		return response
	end

	# creates an embed for general inqueries 
	# eg if the query is simply 'steve jobs'
	def self.nonResultEmbed query, original_input
		response = Discordrb::Webhooks::Embed.new color: ANSWER_COLOUR

		query.each do |pod|
			result_text = ""
			pod.subpods.each do |subpod|
				result_text << subpod.plaintext + "\n"
			end
			response.add_field name: pod.title, value: result_text.toTableIfNecessary unless result_text.strip == ""
		end

		return response unless response.fields.length == 0
		return self.errorEmbed query, "This type of query is not currently supported", original_input
	end
end