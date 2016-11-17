namespace :wealthbox do

  SUCCESS_CODE = 200

  TEST_IDS= {
      contact: 3949217
  }

  CMD_NAME = 0
  CMD_METHOD = 1
  CMD_BODY = 2


  ERROR_NIL_RESPONSE = "Http Request returned a nil response: "

  @api = {
      token:    ENV['RAILS_WEALTHBOX_API_TOKEN'], #'5d915308d7898094f5d410313bd3f2ef',
      base_uri: 'https://api.crmworkspace.com/v1'
  }

  @commands = [
      [ '/contacts', :get, nil ],
      [ "/contacts/#{TEST_IDS[:contact]}", :put, { "nickname" => 'Francis'} ],
  ]

  desc 'Run an API Test'
  task :api_test => :environment do |task, args|
    test_contacts
  end

end

def test_contacts
  errors = []
  @commands.each do |l_command|
    begin
      response  = call_api(l_command[CMD_NAME], l_command[CMD_METHOD], l_command[CMD_BODY])
      errors << response[:error] unless response[:error].nil?
    rescue Exception => error
      errors << error.to_s
    end
  end

  errors
end


def call_api (uri, method, request_body = nil)
  if method == :get
    response = HTTParty.get(@api[:base_uri] + uri, :headers => {"ACCESS_TOKEN" => @api[:token], 'Content-Type' => 'application/json'})  #.parsed_response
  elsif method == :post
    response = HTTParty.post(@api[:base_uri] + uri, :headers => {"ACCESS_TOKEN" => @api[:token], 'Content-Type' => 'application/json'}, :body => request_body.to_json)  #.parsed_response
  elsif method == :put
    response = HTTParty.put(@api[:base_uri] + uri, :headers => {"ACCESS_TOKEN" => @api[:token], 'Content-Type' => 'application/json'}, :body => request_body.to_json)  #.parsed_response
  elsif method ==  :delete
    response = HTTParty.post(@api[:base_uri] + uri, :headers => {"ACCESS_TOKEN" => @api[:token], 'Content-Type' => 'application/json'}, :body => "")  #.parsed_response
  else
    response = nil
  end
  
  results = {
      headers:    response.headers.to_h,
      body:       response.body,
      data:       response.parsed_response,
      code:       response.code,
      message:    response.message,
      success?:   response.code == SUCCESS_CODE,
      error:      response.code == SUCCESS_CODE ? nil : "Http Error: #{response.code} #{response.message}"
  }

  return results
end

