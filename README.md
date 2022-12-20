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

## Local testing

- Navigate to http://api.local-gifted.com:5000/v1/csrf/restore
- Open the developer tools > Application > Cookies and copy the 

### Create user

Request
```js
fetch('http://api.local-gifted.com:5000/v1/users', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', 'X-CSRF-Token': "VALID_TOKEN_HERE"},
    body: JSON.stringify({ user: { email: "test13@test.com", password: "password" } }),
    credentials: 'include'
})
```

Response

Errors
```json
{
  "errors": [
    {
      "code": "too_short",
      "detail": "Password is too short (minimum is 10 characters)",
      "status": "422",
      "title": "Unprocessable Entity"
    }
  ]
}
```