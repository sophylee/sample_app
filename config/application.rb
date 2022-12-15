require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module GiftedApi
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.0

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # Only loads a smaller set of middleware suitable for API only apps.
    # Middleware like session, flash, cookies can be added back manually.
    # Skip views, helpers and assets when generating a new resource.
    config.api_only = true

    # This also configures session_options for use below
    config.session_store :cookie_store, key: '_interslice_session'

    # Required for all session management (regardless of session_store)
    config.middleware.use ActionDispatch::Cookies

    # Added to use cookies for session management
    config.middleware.use ActionDispatch::Session::CookieStore

    config.middleware.use config.session_store, config.session_options

    # Necessary to fix issue where actionpack tries to set flash message after checking CSRF
    config.middleware.use ActionDispatch::Flash

    # Allows the method to be overridden if params[:_method] is set. This is the 
    # middleware which supports the PUT and DELETE HTTP method types.
    config.middleware.use Rack::MethodOverride

    # Set additional headers for security
    config.action_dispatch.default_headers = {
      'Cross-Origin-Embedder-Policy' => 'require-corp',
      'Cross-Origin-Opener-Policy' => 'same-origin',
      'Cross-Origin-Resource-Policy' => 'same-origin',
      'Origin-Agent-Cluster' => '?1',
      'Strict-Transport-Security' => 'max-age=15552000; includeSubDomains'
    }

  end
end
