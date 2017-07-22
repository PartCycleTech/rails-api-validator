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

### Step by step

1. Instantiate:

```ruby
api_validator = ApiValidator.new(spec: my_path_to_spec)
```

2. Build request

```ruby
api_validator.build_request(flex_param_hash)
```

3. Verify response

```ruby
api_validator.verify_response(actual_body, flex_params_array) do |expected_status, expected_body|
  # Test that actual_response is equal to expected_body, and expected_status is equal to whatever is expected
end
```

### Example

Fixture:

```json
{
  "request": {
    "body": {
      "data": {
        "attributes": {
          "to-zip": "35630",
          "delivery-date": null
        },
        "relationships": {
          "inventory-item": {
            "data": {
              "id": "@id",
              "type": "inventory-items"
            }
          }
        },
        "type": "delivery-estimates"
      }
    }
  },
  "response": {
    "status": "202",
    "body": {
      "data": {
        "id": "@id",
        "attributes": {
          "delivery-date": "2017-06-23",
          "to-zip": "35630"
        },
        "type": "delivery-estimates"
      }
    }
  }
}
```

Rails code:

```ruby
describe "POST /delivery-estimates", :vcr do
  let(:est_delivery_date_from_cassette) { Date.new(2017, 6, 21) }
  let(:two_business_days_after_carrier_delivery_date) { 2.business_days.after(est_delivery_date_from_cassette) }
  let(:inventory_item) { FactoryGirl.create(:inventory_item, :shippable_as_freight) }
  let(:api_validator) { ApiValidator.new(spec: 'delivery-estimates/post') }
  let(:data) { api_validator.build_request({ "data.relationships.inventory-item.data.id" => inventory_item.id }) }

  it "responds with delivery estimate" do
    post_jsonapi "/api/delivery-estimates", data.to_json

    api_validator.verify_response(json, ["data.id"]) do |expected_status, expected_body|
      expect_jsonapi_response(expected_status)
      expect(json).to eq expected_body
    end

    estimated_delivery_date = json.dig("data", "attributes", "delivery-date")
    expect(estimated_delivery_date).to eq(two_business_days_after_carrier_delivery_date.to_s)
  end
end
```

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
