require 'discordrb'
require 'wolfram-alpha'

require_relative 'constants.rb'
require_relative 'formatting.rb'

# discord client
discord_bot = Discordrb::Commands::CommandBot.new token: Constants::DISCORD_BOT_TOKEN, client_id: Constants::DISCORD_BOT_ID
# wolfram alpha client
wolfram_alpha_client = WolframAlpha::Client.new Constants::WOLFRAM_ALPHA_TOKEN, { "format" => "plaintext" }
# bot tag regex is stored in this variable
discord_bot_id_regex = nil

# when the bot is mentionned, query wolfram alpha
discord_bot.mention do |event|
	query_text = event.message.content.gsub(discord_bot_id_regex, "").strip
	if query_text.length != 0 then
		query_response = wolfram_alpha_client.query query_text
		formatted_response = WolframAlphaQueryFormatting.format query_response, query_text
		event.channel.send_embed '', formatted_response
		begin
			event.message.delete
		rescue Exception => e
		end
	end
end

# run the bot
discord_bot.run :async
discord_bot_id_regex = Regexp.new "<@#{discord_bot.profile.id}>" # generate the regex
discord_bot.watching=("Your queries | @#{discord_bot.profile.username}##{discord_bot.profile.discriminator} <Query>") # set the playing message to the query format
discord_bot.sync
