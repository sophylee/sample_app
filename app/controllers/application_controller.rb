class ApplicationController < ActionController::API
  # Send CSRF token to client in a cookie with every request
  include ActionController::Cookies
  include ActionController::RequestForgeryProtection
  protect_from_forgery with: :exception
  respond_to :json
  before_action :set_csrf_cookie
  before_action :authenticate_user!
  
  # Error handling
  include JSONAPI::Errors
  rescue_from ActiveRecord::RecordNotFound do |e|
    render jsonapi_errors: e, status: :not_found
  end

  rescue_from ActionController::InvalidAuthenticityToken do |e|
    render jsonapi_errors: [status: 403, title: e.message], status: 403
  end

  private

  def set_csrf_cookie
    token = form_authenticity_token
    cookies["_api_csrf_token"] = { value: token, httponly: true } 
  end
end 
