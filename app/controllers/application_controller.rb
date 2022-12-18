class ApplicationController < ActionController::API
  # Send CSRF token to client in a cookie with every request
  include ActionController::Cookies
  include ActionController::RequestForgeryProtection
  protect_from_forgery with: :exception
  respond_to :json
  before_action :set_csrf_cookie

  # Error handling
  include JSONAPI::Errors
  rescue_from ActiveRecord::RecordNotFound do |e|
    render jsonapi_errors: e, status: :not_found
  end

  private

  def set_csrf_cookie
    cookies["_csrf_token"] = { value: form_authenticity_token, httponly: true } 
  end
end 
