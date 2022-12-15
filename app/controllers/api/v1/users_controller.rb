module Api
  module V1
    class UsersController < ApplicationController
      def test
        render "hi"
      end
    end
  end
end