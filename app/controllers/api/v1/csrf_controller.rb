module Api
  module V1
    class CsrfController < ApplicationController
      skip_before_action :authenticate_user!, only: [:restore]

      def restore
        render json: "hi"
      end
    end
  end
end