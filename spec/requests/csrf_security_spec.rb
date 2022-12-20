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
        expect(response.status).to eq(201)

        # Get the new CSRF token returned by the API to the client. This token should be a masked, 
        # encrypted version of a _different_ CSRF token than the one for the pre-session token. 
        # In other words:
        # 
        # unmask_token(decode_csrf_token(pre_session_csrf_token)) != unmask_token(decode_csrf_token(session_csrf_token))
        # 
        # This is important because .real_csrf_token in ActionController decodes and unmasks the client-facing 
        # CSRF token, then uses .valid_authenticity_token? to compare the token to the global CSRF token for this session. 
        # The global CSRF token for the anonymous session should be different than the global CSRF token for 
        # the authenticated session. Otherwise, someone with the anonymous session CSRF token would be able to 
        # execute a CSRF token fixation attack. In other words: 
        #
        # REAL pre-session CSRF token != REAL session CSRF token
        # 
        # which means that: global_csrf_token(pre_session) != global_csrf_token(session)
        # 
        # which means that: sending the pre_session X-CSRF-TOKEN header in an authenticated request 
        # should NOT work, since ActionController converts this header into a real CSRF token, which is
        # matched against the global CSRF token for the session, and the two are NOT the same. 
        # 
        # All ActionController methods in the above explanation can be found here: 
        # https://github.com/rails/rails/blob/main/actionpack/lib/action_controller/metal/request_forgery_protection.rb
        session_csrf_token = response.header["Set-Cookie"].split(";")[0].split("_api_csrf_token=")[1]
        
        # Since the tokens are masked and encoded, we expect them to look **different**. This doesn't prove yet that the
        # real CSRF token underlying these client-facing tokens are different. We'll prove that in the next few lines.
        expect(pre_session_csrf_token).to_not eq(session_csrf_token)

        # Decode and then unmask the pre_session_csrf_token and session_csrf_token to get their real values
        # The unmasking and decoding code are pulled straight from ActionController RequestForgeryProtection.
        decoded_pre_session_csrf_token = Base64.urlsafe_decode64(pre_session_csrf_token)
        real_pre_session_csrf_token = unmask(decoded_pre_session_csrf_token)

        decoded_session_csrf_token = Base64.urlsafe_decode64(session_csrf_token)
        real_session_csrf_token = unmask(decoded_session_csrf_token)

        expect(real_pre_session_csrf_token).to_not eq(real_session_csrf_token)

        # Now try to make an authenticated request using the pre_session_csrf_token. It should NOT work.
        # We can use the same headers and params as we used for registration. 
        post authenticated_endpoint_api_v1_users_url, params: params, headers: with_pre_session_token_headers
        expect(response.status).to eq(403)
        expect(JSON.parse(response.body)["errors"][0]["title"]).to eq("Can't verify CSRF token authenticity.")

        # Now make a request using the session_token. It SHOULD work.
        with_session_token_headers = { 'Content-Type' => 'application/json', 'X-CSRF-Token' => session_csrf_token }
        post authenticated_endpoint_api_v1_users_url, params: params, headers: with_session_token_headers
        expect(response.status).to eq(200)
        expect(JSON.parse(response.body)["data"]["attributes"]).to eq({"email" => email})
        expect(response.headers["Set-Cookie"].include?("_api_csrf_token=")).to eq(true)

        # Try to sign out the user using the pre_session_csrf_token. It should NOT work.
        delete destroy_user_session_url, headers: with_pre_session_token_headers
        expect(response.status).to eq(403)
        expect(JSON.parse(response.body)["errors"][0]["title"]).to eq("Can't verify CSRF token authenticity.")
        expect(response.headers["Set-Cookie"].include?("_api_csrf_token=")).to_not eq(true)

        # Sign out the user using the session_csrf_token. It SHOULD work.
        delete destroy_user_session_url, headers: with_session_token_headers
        expect(response.status).to eq(204)
        expect(response.headers["Set-Cookie"].include?("_api_csrf_token=")).to eq(true)

        # Now try to sign in again using the pre_session_csrf_token. It should NOT work.
        post user_session_url, params: params, headers: with_pre_session_token_headers
        expect(response.status).to eq(403)
        expect(JSON.parse(response.body)["errors"][0]["title"]).to eq("Can't verify CSRF token authenticity.")
        expect(response.headers["Set-Cookie"].include?("_api_csrf_token=")).to eq(false)

        # Do the same, this time with the session_csrf_token. It still shouldn't work.
        post user_session_url, params: params, headers: with_session_token_headers
        expect(response.status).to eq(403)
        expect(JSON.parse(response.body)["errors"][0]["title"]).to eq("Can't verify CSRF token authenticity.")
        expect(response.headers["Set-Cookie"].include?("_api_csrf_token=")).to eq(false)

        # Get a new pre-session CSRF token. This time the request to sign in should work.
        get restore_api_v1_csrf_url
        new_pre_session_csrf_token = response.header["Set-Cookie"].split(";")[0].split("_api_csrf_token=")[1]
        with_new_pre_session_token_headers = { 'Content-Type' => 'application/json', 'X-CSRF-Token' => new_pre_session_csrf_token }
        post user_session_url, params: params, headers: with_new_pre_session_token_headers
        expect(response.status).to eq(201)
        expect(JSON.parse(response.body)["email"]).to eq(email) # TODO update devise sessions controller to use json serializer
        expect(response.headers["Set-Cookie"].include?("_api_csrf_token=")).to eq(true)
      end
    end

    # Pulled directly from https://github.com/rails/rails/blob/main/actionpack/lib/action_controller/metal/request_forgery_protection.rb#L507-L513    
    def unmask(decoded_csrf_token)
      one_time_pad = decoded_csrf_token[0...32]
      encrypted_csrf_token = decoded_csrf_token[32..-1]
      encrypted_csrf_token = encrypted_csrf_token.dup
      size = one_time_pad.bytesize
      i = 0
      while i < size
        encrypted_csrf_token.setbyte(i, one_time_pad.getbyte(i) ^ encrypted_csrf_token.getbyte(i))
        i += 1
      end
      return encrypted_csrf_token
    end
  end  
end