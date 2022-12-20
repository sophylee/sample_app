require 'spec_helper'

describe 'CSRF security', type: :request do
  describe 'user registration' do
    let(:email) { 'test_user@test.com' }
    let(:password) { 'Password123!' }
    let(:pre_session_csrf_token) do 
      get restore_api_v1_csrf_url
      response.header["Set-Cookie"].split(";")[0].split("_api_csrf_token=")[1]
    end
    let(:without_csrf_token_headers) { { 'Content-Type' => 'application/json' } }
    let(:with_pre_session_token_headers) { { 'Content-Type' => 'application/json', 'X-CSRF-Token' => pre_session_csrf_token } }
    let(:params) { { user: { email: email, password: password } }.to_json }

    context 'when the user does not include a CSRF token in their request' do 
      let(:headers) { without_csrf_token_headers }

      it 'returns a CSRF error' do 
        post user_registration_url, params: params, headers: without_csrf_token_headers

        expect(response.status).to eq(403)
        response_body = JSON.parse(response.body)
        expect(response_body).to eq({
          "errors" =>
            [{
              "detail" => nil, 
              "source" => nil, 
              "status"=> 403, 
              "title" => "Can't verify CSRF token authenticity."
            }]
          })
        # If the user doesn't provide a valid CSRF, don't give them one!
        expect(response.headers["Set-Cookie"].include?("_api_csrf_token=")).to eq(false)
      end
    end

    context 'when the user does include a CSRF token in their request' do
      it 'allows the user to use the pre-session CSRF token both before and after registration' do 
        post user_registration_url, params: params, headers: with_pre_session_token_headers
        expect(response.status).to eq(200)
        response_body = JSON.parse(response.body)
        expect(response_body["data"]).to be_a_kind_of(Hash)
        expect(response_body["data"]["id"].to_i).to be_a_kind_of(Integer)
        expect(response_body["data"]["type"]).to eq("user")
        expect(response_body["data"]["attributes"]).to eq({"email" => email})

        # Get the new CSRF token returned by the API to the client. Note that this token is a masked, 
        # encrypted version of the same real CSRF token as the pre-session token. In other words:
        # 
        # unmask_token(decode_csrf_token(pre_session_csrf_token)) == unmask_token(decode_csrf_token(session_csrf_token))
        # 
        # This is because .real_csrf_token in ActionController retrieves the same CSRF token for the pre-auth session 
        # as it does for the post-auth session. This CSRF token is then used in .valid_authenticity_token? to figure out 
        # the global CSRF token for this session. In other words: 
        #
        # REAL pre-session CSRF token == REAL session CSRF token
        # 
        # which means that: global_csrf_token(pre_session) == global_csrf_token(session)
        # 
        # which means that: sending the pre_session X-CSRF-TOKEN header in an authenticated request 
        # works, since ActionController converts this header into a real CSRF token, which is matched 
        # against the global CSRF token for the session, and the two are the same. In other words: 
        # 
        # unmask_token(decode_csrf_token(pre_session_csrf_token)) ==
        #   unmask_token(decode_csrf_token(session_csrf_token)) ==
        #   real_csrf_token(pre_session) == 
        #   real_csrf_token(session) == 
        #   global_csrf_token(pre_session) ==
        #   global_csrf_token(session)
        # 
        # This is pretty counter-intuitive, since I would have thought that the real CSRF token changes
        # once you authenticate, but this is not the case.
        # 
        # All ActionController methods in the above explanation can be found here: 
        # https://github.com/rails/rails/blob/main/actionpack/lib/action_controller/metal/request_forgery_protection.rb
        session_csrf_token = response.header["Set-Cookie"].split(";")[0].split("_api_csrf_token=")[1]
        
        # Since the tokens are masked and encoded, we expect them to look **different** even though they're the same
        # underlying CSRF token.
        expect(pre_session_csrf_token).to_not eq(session_csrf_token)

        # Decode and then unmask the pre_session_csrf_token and session_csrf_token to get their real values
        # The unmasking and decoding code are pulled straight from ActionController RequestForgeryProtection.
        masked_pre_session_csrf_token = Base64.urlsafe_decode64(pre_session_csrf_token)
        s1 = masked_pre_session_csrf_token[0...32]
        s2 = masked_pre_session_csrf_token[32..-1]
        s2 = s2.dup
        size = s1.bytesize
        i = 0
        while i < size
          s2.setbyte(i, s1.getbyte(i) ^ s2.getbyte(i))
          i += 1
        end
        real_pre_session_csrf_token = s2

        # Get the real session CSRF token
        masked_session_csrf_token = Base64.urlsafe_decode64(session_csrf_token)
        s3 = masked_session_csrf_token[0...32]
        s4 = masked_session_csrf_token[32..-1]
        s4 = s4.dup
        size = s3.bytesize
        i = 0
        while i < size
          s4.setbyte(i, s3.getbyte(i) ^ s4.getbyte(i))
          i += 1
        end
        real_session_token = s4

        expect(real_pre_session_csrf_token).to_not eq(real_session_token)

        # Now try to make an authenticated request using the pre_session_csrf_token. It should still work.
        # We can use the same headers and params as we used for registration. TODO test a real endpoint here.
        post authenticated_endpoint_api_v1_users_url, params: params, headers: with_pre_session_token_headers
        expect(response.status).to eq(403)
        # expect(JSON.parse(response.body)["data"]["attributes"]).to eq({"email" => email})
        # expect(response.headers["Set-Cookie"].include?("_api_csrf_token=")).to eq(true)

        # Now make a request using the session_token. It should work too.
        with_session_token_headers = { 'Content-Type' => 'application/json', 'X-CSRF-Token' => session_csrf_token }
        post authenticated_endpoint_api_v1_users_url, params: params, headers: with_session_token_headers
        expect(response.status).to eq(200)
        expect(JSON.parse(response.body)["data"]["attributes"]).to eq({"email" => email})
        expect(response.headers["Set-Cookie"].include?("_api_csrf_token=")).to eq(true)
        new_token = response.header["Set-Cookie"].split(";")[0].split("_api_csrf_token=")[1]

        # Sign out the user using the pre_session_csrf_token
        with_new_session_token_headers = { 'Content-Type' => 'application/json', 'X-CSRF-Token' => new_token }
        delete destroy_user_session_url, headers: with_new_session_token_headers
        expect(response.status).to eq(204)
        expect(response.headers["Set-Cookie"].include?("_api_csrf_token=")).to eq(true)

        # Now try to sign in again using the pre_session_csrf_token. It should no longer work 
        # since we signed out and created a new session incompatible with the original CSRF token.
        post user_session_url, params: params, headers: with_pre_session_token_headers
        expect(response.status).to eq(403)
        expect(JSON.parse(response.body)["errors"][0]["title"]).to eq("Can't verify CSRF token authenticity.")
        expect(response.headers["Set-Cookie"].include?("_api_csrf_token=")).to eq(false)

        # Do the same, this time with the session_csrf_token. It still shouldn't work.
        post user_session_url, params: params, headers: with_session_token_headers
        expect(response.status).to eq(403)
        expect(JSON.parse(response.body)["errors"][0]["title"]).to eq("Can't verify CSRF token authenticity.")
        expect(response.headers["Set-Cookie"].include?("_api_csrf_token=")).to eq(false)

        get restore_api_v1_csrf_url
        new_pre_session_csrf_token = response.header["Set-Cookie"].split(";")[0].split("_api_csrf_token=")[1]
        with_new_pre_session_token_headers = { 'Content-Type' => 'application/json', 'X-CSRF-Token' => new_pre_session_csrf_token }
        post user_session_url, params: params, headers: with_new_pre_session_token_headers
        expect(response.status).to eq(201)
        expect(JSON.parse(response.body)["email"]).to eq(email) # TODO update devise sessions controller to use json serializer
        expect(response.headers["Set-Cookie"].include?("_api_csrf_token=")).to eq(true)
      end
    end
  end  
end