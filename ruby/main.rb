require 'httparty'
require 'json'
trap("SIGINT") { puts "stopped the script with peace!"; exit }

def clear_screen
  system('clear')
end

# ANSI color codes
LIGHT_BLUE = "\e[34m"
PLAIN_TEXT = "\e[37m"
RED = "\e[31m"
GREEN = "\e[32m"
YELLOW = "\e[33m"
MAGENTA = "\e[35m"
BRIGHT_BACKGROUND = "\e[47m"
RED_BACKGROUND = "\e[41m"
RESET = "\e[0m"

def make_request(url, headers, data = nil)
  loop do
    begin
      response = if data
                   HTTParty.post(url, headers: headers, body: data)
                 else
                   HTTParty.get(url, headers: headers)
                 end
      return response.body if response.success?
    rescue StandardError
      puts "\e[1;33mCheck Your Connection!\n"
      sleep(2)
    end
  end
end

def extract_data(start_marker, end_marker, data)
  data[/#{Regexp.escape(start_marker)}(.*?)#{Regexp.escape(end_marker)}/m, 1]
end

def countdown_timer(seconds)
  end_time = Time.now + seconds
  while Time.now < end_time
    print "\r                        \r"
    remaining = (end_time - Time.now).to_i
    print Time.at(remaining).utc.strftime("%H:%M:%S")
    sleep(1)
  end
end

# Load configuration
require_relative 'config'

# Main loop
loop do
  url = "https://prod-supra-bff-blastoff.services.supra.com/graphql"
  headers = {
    "Host" => "prod-supra-bff-blastoff.services.supra.com",
    "User-Agent" => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0.0.0 Safari/537.36",
    "Authorization" => AUTH_TOKEN,
    "Content-Type" => "application/json",
    "Referer" => "https://supra.com/",
    "Accept-Language" => "id-ID,id;q=0.9,en-US;q=0.8,en;q=0.7,zh-TW;q=0.6,zh;q=0.5",
    "Accept" => "*/*"
  }

  get_total_transactions_query = {
    operationName: "getTotalTransactions",
    variables: {},
    query: "query getTotalTransactions { getTotalTransactionCount }"
  }.to_json

  total_transactions_response = make_request(url, headers, get_total_transactions_query)
  total_transaction_count = extract_data('"getTotalTransactionCount":', '}', total_transactions_response)

  user_stats_query = {
    operationName: "Query",
    variables: { input: { isManualFetch: true } },
    query: "query Query($input: starcadeUserStatisticInput) { starcadeUserLeaderBoardData(input: $input) }"
  }.to_json

  user_stats_response = make_request(url, headers, user_stats_query)
  user_total_transactions = extract_data('"userTotalTransaction":', ',"', user_stats_response)
  user_rewards = extract_data('"userRewards":', ',"', user_stats_response)
  transactions_to_top_100 = extract_data('"txnToTop100":', ',"', user_stats_response)
  last_updated_date = extract_data('lastUpdatedDate":"', '"', user_stats_response)

  dice_game_query = {
    operationName: "getTotalDiceGamePlay",
    variables: { input: { gameId: 2 } },
    query: "query getTotalDiceGamePlay($input: totalAttemptLeftInput!) { totalUserAttemptLeftCount(input: $input) }"
  }.to_json

  dice_game_response = make_request(url, headers, dice_game_query)
  dice_attempts_left = extract_data('"totalUserAttemptLeftCount":', '}', dice_game_response)

  supra_token = "supra"
  coingecko_url = "https://api.coingecko.com/api/v3/simple/price?ids=#{supra_token}&vs_currencies=USD&include_market_cap=true&include_24hr_vol=true&include_24hr_change=true&include_last_updated_at=true"
  coingecko_headers = {
    "Accept" => "application/json",
    "User-Agent" => headers["Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0.0.0 Safari/537.36"]
  }

  coingecko_response = make_request(coingecko_url, coingecko_headers)
  supra_price = extract_data('usd":', ',', coingecko_response)
  market_cap = extract_data('cap":', ',', coingecko_response)
  volume_24h = extract_data('vol":', ',', coingecko_response)
  rewards_in_usd = user_rewards.to_f * supra_price.to_f

  clear_screen

  puts """
--------------------------------------------
              Token Info
--------------------------------------------
#{YELLOW}+)> #{RESET}#{supra_token}

#{RESET}PRICE     #{RED}: #{RESET}#{supra_price} USD
#{RESET}MARKETCAP #{RED}: #{LIGHT_BLUE}#{market_cap} #{RESET}USD
#{RESET}VOL24     #{RED}: #{RESET}#{volume_24h} USD
--------------------------------------------
              User Info
--------------------------------------------
#{YELLOW}+)> #{RESET}lastUpdatedDate: #{GREEN}#{last_updated_date} #{RESET}
#{YELLOW}+)> #{RESET}getTotalTxCount: #{LIGHT_BLUE}#{total_transaction_count} #{RESET}Tx #{RESET}
#{YELLOW}+)> #{RESET}totalUsersTx   : #{GREEN}#{user_total_transactions} #{RESET}Tx #{RESET}
#{YELLOW}+)> #{RESET}UserReward     : #{LIGHT_BLUE}#{user_rewards} #{RESET}Supra #{RESET}
#{YELLOW}+)> #{RESET}RewardinUsd    : #{GREEN}#{rewards_in_usd} #{RESET}USD #{RESET}
#{YELLOW}+)> #{RESET}txnToTop100    : #{LIGHT_BLUE}#{transactions_to_top_100} #{RESET}Tx #{RESET}
--------------------------------------------
#{YELLOW}+)> #{RESET}LeftCount: #{LIGHT_BLUE}#{dice_attempts_left} #{RESET}More Dice #{RESET}
--------------------------------------------

"""

  countdown_timer(821)
end

