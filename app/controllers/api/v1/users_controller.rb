module Api
  module V1
    class UsersController < ApplicationController
      def authenticated_endpoint
        render json: UserSerializer.new(current_user).serializable_hash.to_json
      end
    end
  end
end