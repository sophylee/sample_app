module Api
  module V1
    class Users::SessionsController < Devise::SessionsController
      include ActionController::MimeResponds
    end
  end
end