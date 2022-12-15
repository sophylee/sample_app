module Api
  module V1
    class Users::RegistrationsController < Devise::RegistrationsController
      def create
        build_resource(sign_up_params)
        
        if resource.save
          if resource.active_for_authentication?
            sign_up(resource_name, resource)
            render UserSerializer.new(resource).serializable_hash.to_json
          else
            render UserSerializer.new(resource).serializable_hash.to_json
          end
        else
          clean_up_passwords resource
          render jsonapi_errors: resource.errors, status: :unprocessable_entity
        end
      end
    end
  end
end