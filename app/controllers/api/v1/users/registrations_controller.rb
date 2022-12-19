module Api
  module V1
    class Users::RegistrationsController < Devise::RegistrationsController
      def create
        build_resource(sign_up_params)
        
        if resource.save
          sign_up(resource_name, resource)
          render json: UserSerializer.new(resource).serializable_hash.to_json
        else
          clean_up_passwords resource
          render jsonapi_errors: resource.errors, status: :unprocessable_entity
        end
      end
    end
  end
end