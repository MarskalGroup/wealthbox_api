namespace :wealthbox do

  SUCCESS_CODE = 200

  TEST_IDS= {
      contact: 3949217
  }

  CMD_NAME = 0
  CMD_METHOD = 1
  CMD_EXPECTED_DATA_KEYS = 2
  CMD_BODY = 3


  ERROR_NIL_RESPONSE = "Http Request returned a nil response: "

  @api = {
      token:    ENV['RAILS_WEALTHBOX_API_TOKEN'], #'5d915308d7898094f5d410313bd3f2ef',
      base_uri: 'https://api.crmworkspace.com/v1'
  }

  COMMON_EXPECTED_KEYS = {
      contacts: ['contacts', 'meta' ],
      tasks: ['tasks', 'meta' ],
      id:       ['id' ],
  }

  @commands = [
      [ '/contacts', :get, COMMON_EXPECTED_KEYS[:contacts], nil ],
      [ "/contacts/#{TEST_IDS[:contact]}", :put, COMMON_EXPECTED_KEYS[:id], { "nickname" => 'Francis1'} ],
      [ "/contacts?email=sam@example.org", :get, COMMON_EXPECTED_KEYS[:contacts], nil ],
      [ '/tasks', :get, COMMON_EXPECTED_KEYS[:tasks], nil ],
      [ '/tasks', :post, COMMON_EXPECTED_KEYS[:id], {
          "name" =>  "Return Bill's call",
          "due_date" => "2016-11-24 11:00 AM -500",
      } ],
  ]

  desc 'Run an API Test'
  task :api_test => :environment do |task, args|
    results = test_contacts

    puts "\n\nFinal Results:\n\t\t"
    puts " Tried: #{results[:tried]},  Succeeded: #{results[:success]},   Failed: #{results[:fail]}\n\n"

    unless results[:errors].empty?
      print "\n\tList of #{results[:errors].length} Error(s)\n\t\t"
      puts results[:errors].join("\n\t\t")
    end
  end

end

def test_contacts
  results = {
      tried: 0,
      success: 0,
      fail: 0,
      errors: []
  }
  puts "\n\nTesting #{@commands.length} Commands:"
  @commands.each do |l_command|
    begin
      response  = call_api(l_command[CMD_NAME], l_command[CMD_METHOD], l_command[CMD_EXPECTED_DATA_KEYS], l_command[CMD_BODY])
      results = build_result_message(results, l_command, response[:error])
    rescue Exception => error
      results << build_result_message(results, l_command, error.to_s)
    end
  end

  results
end

def build_result_message(p_results, p_command, p_error)
  l_api_call_text = "Api Call Api Call[#{p_command[CMD_NAME]}, #{p_command[CMD_METHOD]}, #{p_command[CMD_BODY]}] "
  puts "\t#{l_api_call_text }...#{p_error.blank? ? "Success!!" : '**FAILED**'}"

  p_results[:tried] += 1
  if p_error.blank?
    p_results[:success] += 1
  else
    p_results[:fail] += 1
    p_results[:errors] << "Error: #{p_error} ==>  #{l_api_call_text}"
  end
  p_results
end


def call_api (uri, method, expected_keys, request_body = nil)
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

  results[:error] = check_for_expected_keys(results[:data], expected_keys) if results[:success?]

  return results
end


def check_for_expected_keys(p_data, p_expected_keys)
  return nil if !p_expected_keys.is_a?(Array) || p_expected_keys.empty?   #if no keys are expected then just return a nil value

  expected_keys = ''
  p_expected_keys.each do |l_key|
    unless p_data.has_key?(l_key)
      expected_keys +=  ', ' unless expected_keys.blank?
      expected_keys += "#{l_key}"
    end

  end

  expected_keys.blank? ? nil : "Expected response keys not found `#{expected_keys}`"

end

