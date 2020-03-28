require 'httparty'
require 'pp'
require 'redis'
require 'json'
require 'pry'
require 'sinatra'
require 'twilio-ruby'
require 'xmlsimple'

redis = Redis.new

########## SEED SCRIPT ##########################################################################

response_body = HTTParty.get('https://travel.state.gov/_res/rss/TAsTWs.xml').body

hash = XmlSimple.xml_in(response_body.to_s)

res = hash.values[2].first['item'].first['title'].first.split(" - ")

hash.values[2].first['item'].each do |el|
	res = el['title'].first.split(" - ")
  res_hash = { "title" => res[1], "pubDate" => el['pubDate'].first, "link" => el['link'].first }.to_json

	redis.set(res[0].downcase.strip, res_hash)
end

# blah = JSON.parse(redis.get('bhutan'))
# pp JSON.parse(redis.get('italy'))

# pp "#{blah['title']} #{blah['link']}"

# pp hash.values[2].first['item']

######### SEND A TEXT MESSAGE ##########################################################################

# account_sid = 'AC7cc8d97bd45ff0bebd419878b45ab98f'
# auth_token = '592365d069896757c8e19bca846fd293'
# client = Twilio::REST::Client.new(account_sid, auth_token)

# from = '+12059004164' # Your Twilio number
# to = '+19896000145' # Your mobile phone number

# client.messages.create(
# from: from,
# to: to,
# body: "Respond with a country name, first letter capitalized"
# )

# puts JSON.parse(redis.get('asdf'))

########## WEBHOOK #########################################################################################

post '/sms-quickstart' do
  twiml = Twilio::TwiML::MessagingResponse.new do |r|
  	input = params['Body'].downcase.strip
    puts input
  	message = "No information for #{input}"

  	unless redis.get(input).nil?
  		value = JSON.parse(redis.get(input))
  		message = "#{value['title']}\n\n#{value['link']}"
    end

    r.message(body: message)
  end

  twiml.to_s
end





# 1. script to seed cache
# 2.
#   a. cron job to update cache
#   b. text me when update occurs 
# 3. be able to text name of a country and get back full report
# 4. be able to get an update of what's changed in the past week/month
# 5. allow people to subscribe to updates
