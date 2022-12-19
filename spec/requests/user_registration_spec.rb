require 'spec_helper'

describe 'User registration', type: :request do
  def get_presession_csrf_token_and_create_user
    # Get a pre-session CSRF token. Note that Rails will consider this token valid even for authenticated
    # requests by the same user. 
    # 
    # /v1/csrf/restore
    get restore_api_v1_csrf_url 
    pre_session_csrf_token = response.header["Set-Cookie"].split(";")[0].split("_api_csrf_token=")[1]

    # POST /v1/users to create a new user
    headers = { 'Content-Type' => 'application/json', 'X-CSRF-Token' => pre_session_csrf_token }
    params = { user: { email: email, password: password } }.to_json
    post user_registration_url, params: params, headers: headers
  end

  describe 'with valid attributes' do 
    let(:email) { 'test_user@test.com' }
    let(:password) { 'Password123!' }

    it 'creates a user' do
      get_presession_csrf_token_and_create_user

      expect(response.status).to eq(200)
      response_body = JSON.parse(response.body)
      expect(response_body["data"]).to be_a_kind_of(Hash)
      expect(response_body["data"]["id"].to_i).to be_a_kind_of(Integer)
      expect(response_body["data"]["type"]).to eq("user")
      expect(response_body["data"]["attributes"]).to eq({"email" => email})
    end
  end

  describe 'with too short of a password' do 
    let(:email) { 'test_user@test.com' }
    let(:password) { 'apples' }

    it 'does not create a user and returns errors' do 
      get_presession_csrf_token_and_create_user

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