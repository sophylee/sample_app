Rails.application.routes.draw do
  # Defines the root path route ("/")
  root to: proc { [200, {}, ['']] }
  draw(:api)
end
