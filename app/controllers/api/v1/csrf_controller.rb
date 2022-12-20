module Api
  module V1
    class CsrfController < ApplicationController
      skip_before_action :authenticate_user!, only: [:restore]

      def restore
        render :head
      end
    end
  end
end