require 'discordrb'
require 'wolfram-alpha'

require_relative 'constants.rb'
require_relative 'formatting.rb'
require_relative 'logging.rb'

# discord client
discord_bot = Discordrb::Commands::CommandBot.new token: Constants::DISCORD_BOT_TOKEN, client_id: Constants::DISCORD_BOT_ID
# wolfram alpha client
wolfram_alpha_client = WolframAlpha::Client.new Constants::WOLFRAM_ALPHA_TOKEN, { "format" => "plaintext" }
# bot tag regex is stored in this variable
discord_bot_id_regex = / /

# when the bot is mentionned, query wolfram alpha
# logging id: 1
discord_bot.mention do |event|
	query_text = event.message.content.gsub(discord_bot_id_regex, "").strip
	Logging.log("Query", query_text, "Start", 1)
	if query_text.length != 0 then
		query_response = wolfram_alpha_client.query query_text
		Logging.log("Query", query_text, "Server Response", 1)
		formatted_response = WolframAlphaQueryFormatting.format query_response, query_text
		Logging.log("Query", query_text, "Formatted", 1)
		
		(0...formatted_response.length).each do |page_number|
			begin
				event.channel.send_embed "`MESSAGE #{page_number + 1} OF #{formatted_response.length}`", formatted_response[page_number]
				Logging.log("Query", query_text, "Response #{page_number + 1}/#{formatted_response.length} Success", 1)
			rescue RestClient::BadRequest => e
				event.respond "`MESSAGE #{page_number + 1} OF #{formatted_response.length} FAILED TO SEND`"
				Logging.log("Query", query_text, "Response #{page_number + 1}/#{formatted_response.length} Failed", 1)
			end
			sleep(1) # prevent rate limiting
		end
		Logging.log("Query", query_text, "Response Fully Sent", 1)

		begin
			event.message.delete
			Logging.log("Query", query_text, "Original Message Deleted", 1)
		rescue Exception => e
			Logging.log("Query", query_text, "Original Message Not Deleted", 1)
		end
	end
	Logging.log("Query", query_text, "End", 1)
end

# run the bot
discord_bot.run :async
puts "[Bot Invite Link] https://discordapp.com/oauth2/authorize?client_id=#{discord_bot.profile.id}&scope=bot&permissions=8192"
discord_bot_id_regex = Regexp.new "<@#{discord_bot.profile.id}>" # generate the regex
discord_bot.watching=("Your queries | @#{discord_bot.profile.username}##{discord_bot.profile.discriminator} <Query>") # set the playing message to the query format
discord_bot.sync
