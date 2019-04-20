require 'discordrb'
require 'wolfram-alpha'

require_relative 'tables.rb'
require_relative 'logging.rb'

# module to contain all formatting data
module WolframAlphaQueryFormatting
	# colour used for responses
	ANSWER_COLOUR = 0xffff00
	#colour used for error messages
	ERROR_COLOUR = 0xff0000
	# holds maximum number of characters per page 
	CHAR_LIMIT_PER_PAGE = 1000

	# function to choose which formatting method needs to be used
	# logging id: 2
	def self.format query, original_input
		return self.toEmbed self.paginate([["Original Input", original_input], ["Error", "No data was received from Wolfram|Alpha"]]) if query == nil
		Logging.log("Formatting", "Query Null Test", "Passed", 2)
		raw_data = self.getPodData query, original_input
		Logging.log("Formatting", "Raw Data", "Parsed Pods", 2)
		paginated_data = self.paginate raw_data
		Logging.log("Formatting", "Paigination", "Pagination Complete", 2)
		return self.toEmbed paginated_data
	end

	# function to get input interpretation
	# logging id: 3
	def self.getInput query, original_input
		Logging.log("Processing", "Input", "Called for Input", 3)
		input_interpretation = query["Input"]
		return [input_interpretation.title, input_interpretation.subpods[0].plaintext] unless input_interpretation == nil
		Logging.log("Processing", "Input", "No Input Interpretation Returned", 3)
		return ["Original Input", original_input]
	end

	# function to check the result
	# logging id: 7
	def self.getTitleDataPair title, content, error_message
		Logging.log("Title Data Pair", "Validation", "Function Called", 7)
		return ["Error", error_message] if title == "" or content == ""
		Logging.log("Title Data Pair", "Validation", "Not Valid", 7)
		return [title, content]
	end

	# function to transform the query into an array of title, text pairs
	# logging id: 4
	def self.getPodData query, original_input
		pod_data = [self.getInput(query, original_input)]
		Logging.log("Pod Parsing", "Input Parsing", "Got Input Parsing", 4)

		if query.find {|pod| pod.title == "Result"} != nil then
			Logging.log("Pod Parsing", "Result", "Definite Result Found", 4)
			result = query.find {|pod| pod.title == "Result"}
			pod_data << self.getTitleDataPair(result.title, result.subpods[0].plaintext.toTableIfNecessary, "Queries must result in plain text only")
		elsif query.find {|pod| pod.title == "Results"} != nil then
			Logging.log("Pod Parsing", "Results", "Definite Results Found", 4)
			result = query.find {|pod| pod.title == "Results"}
			result_body_text = ""
			result.subpods.each do |subpod|
				result_body_text << subpod.plaintext.toTableIfNecessary + "\n"
			end
			pod_data << self.getTitleDataPair(result.title, result_body_text, "Queries must result in plain text only")
		else
			Logging.log("Pod Parsing", "General Formatting", "Defaulted To General Formatting", 4)
			query.each do |pod|
				if !(pod.title.include? "Input") then
					result_body_text = ""
					pod.subpods.each do |subpod|
						result_body_text << subpod.plaintext.toTableIfNecessary + "\n"
					end
					pod_data << [pod.title, result_body_text] unless result_body_text.strip == "" or pod.title == ""
				end
			end
			pod_data << ["Error", "No displayable data was returned"] if pod_data.length < 2
			Logging.log("Pod Parsing", "General Formatting", "No data was actually found", 4) if pod_data.length < 2
		end
		
		return pod_data
	end

	# function to transform the 2d array to 2000 character blocks
	# logging id: 5
	def self.paginate data
		pages = []
		
		while data.length > 0 do
			page_length = 0
			page = []

			while page_length < CHAR_LIMIT_PER_PAGE and data.any? do
				current_clause = data.shift
				page_length += current_clause[0].length + current_clause[1].length
				page << current_clause
			end
			Logging.log("Pagination", "Filling", "Page #{pages.length + 1} Filled", 5)

			if page_length >= CHAR_LIMIT_PER_PAGE then
				Logging.log("Pagination", "Overflow", "Overflow Found", 5)
				overflow_amount = CHAR_LIMIT_PER_PAGE - page_length

				continued_clause = [page[-1][0] + "(cont'd)"]

				if page[-1][1][overflow_amount..-1].include? "```" then
					continued_clause << "```" + page[-1][1][overflow_amount..-1].gsub(/```/, "") + "```"
					Logging.log("Pagination", "Overflow", "Fixed Table For Left Text", 5)
				else
					continued_clause << page[-1][1][overflow_amount..-1]
				end

				if page[-1][1][0...overflow_amount].include? "```" then
					page[-1][1] = "```" + page[-1][1][0...overflow_amount].gsub(/```/, "") + "```"
					Logging.log("Pagination", "Overflow", "Fixed Table For Removed Text", 5)
				else
					page[-1][1] = page[-1][1][0...overflow_amount]
				end

				data = data.unshift continued_clause
				Logging.log("Pagination", "Overflow", "Re-Queued Overflow", 5)
			end

			pages << page
			Logging.log("Pagination", "Processing", "Added To List Of Pages", 5)
		end

		return pages
	end

	# transform the 2000 character block sections to embeds
	# logging id: 6
	def self.toEmbed pages
		embeds = []

		pages.each do |page|
			embed = Discordrb::Webhooks::Embed.new color: (page.any? { |a| a.include? "Error" } ? ERROR_COLOUR : ANSWER_COLOUR)
			Logging.log("Embed Conversion", "Processing", "Created new Embed", 6)
			
			page.each do |clause|
				embed.add_field name: clause[0], value: clause[1]
			end
			Logging.log("Embed Conversion", "Processing", "Filled new Embed", 6)

			embeds << embed
			Logging.log("Embed Conversion", "Processing", "Apended Embed To List", 6)
		end

		return embeds
	end
end
