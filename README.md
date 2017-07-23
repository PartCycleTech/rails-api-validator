# ApiValidator

Rails gem for testing against [partcycle-api-fixtures](https://github.com/PartCycleTech/partcycle-api-fixtures)

## Installation

Add this line to your application's Gemfile:

```ruby
gem "api_validator", git: "git@github.com:PartCycleTech/rails-api-validator.git"
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install api_validator

## Usage

1. Instantiate

```ruby
api_validator = ApiValidator.new(fixture_path: "path/to/my/fixture")
```

2. Build request

```ruby
flex_params_hash = { "path.to.flex.param" => "value to substitute" }

api_validator.build_request(flex_params_hash)
```

3. Verify response

```ruby
flex_params_array = ["path.to.flex.param"]

api_validator.verify_response(actual_body, flex_params_array) do |expected_status, expected_body|
  # Test that actual_response is equal to expected_body, and expected_status is equal to whatever is expected
end
```

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
