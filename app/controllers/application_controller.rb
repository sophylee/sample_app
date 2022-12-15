class ApplicationController < ActionController::API
  include ActionController::Cookies
  include ActionController::RequestForgeryProtection

  protect_from_forgery with: :exception

  before_action :set_csrf_cookie

  private

  def set_csrf_cookie
    cookies["_csrf_token"] = form_authenticity_token
  end
end 
