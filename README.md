# README

## Local setup

Use Ruby 3.1.3
```
rvm install 3.1.3
rvm use 3.1.3
```

Start server
```
rackup -p 5000
```

## API

### Create user

Request
```
fetch('http://api.local-gifted.com:5000/v1/users', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', 'X-CSRF-Token': "VALID_TOKEN_HERE"},
    body: JSON.stringify({ user: { email: "test13@test.com", password: "password" } }),
    credentials: 'include'
})
```

Response

Errors
```
{
  errors: [
    {
      code: "too_short",
      detail: "Password is too short (minimum is 10 characters)",
      status: "422",
      title: "Unprocessable Entity"
    }
  ]
}
```