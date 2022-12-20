# README

## Local setup

Set up test database
```
bin/rake db:create RAILS_ENV=test
```

Run relevant test
```
rspec spec/requests/csrf_security_spec.rb
```