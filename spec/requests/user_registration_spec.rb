require 'spec_helper'

describe 'User registration', type: :request do
  describe 'with valid attributes' do 
    it 'creates a user' do 
      get test_api_v1_users_url
      csrf_token = response.header["Set-Cookie"].split(";")[0].split("_csrf_token=")[1]

      headers = { 'Content-Type' => 'application/json', 'X-CSRF-Token' => csrf_token }
      params = { user: { email: "test13@test.com", password: "password123" } }.to_json
      post user_registration_url, params: params, headers: headers

      expect(response.status).to eq(200)
      response_body = JSON.parse(response.body)
      expect(response_body["data"]).to be_a_kind_of(Hash)
      expect(response_body["data"]["id"].to_i).to be_a_kind_of(Integer)
      expect(response_body["data"]["type"]).to eq("user")
      expect(response_body["data"]["attributes"]).to eq({"email"=>"test13@test.com"})
    end
  end

  describe 'with too short of a password' do 
    it 'creates a user' do 
      get test_api_v1_users_url
      csrf_token = response.header["Set-Cookie"].split(";")[0].split("_csrf_token=")[1]

      headers = { 'Content-Type' => 'application/json', 'X-CSRF-Token' => csrf_token}
      params = { user: { email: "test13@test.com", password: "password" } }.to_json
      post user_registration_url, params: params, headers: headers

      expect(response.status).to eq(422)
      response_body = JSON.parse(response.body)
      expect(response_body["errors"]).to be_a_kind_of(Array)
      expect(response_body["errors"][0]).to eq({
        "status" => "422", 
        "source" => { "pointer" => "" }, 
        "title" => "Unprocessable Entity", 
        "detail" => "Password is too short (minimum is 10 characters)", 
        "code" => "too_short"
      })
    end
  end  
end