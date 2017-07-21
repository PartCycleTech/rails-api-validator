require "api_validator/version"
require "active_support/all"

class ApiValidator
  attr_reader :spec

  def initialize(options)
    path = options[:spec]
    fixture = options[:fixture]
    @spec = path ? load_api_fixture(path) : fixture
  end

  def build_request(flex_params = [])
    spec_body = spec["request"]["body"].deep_dup

    flex_params.each do |key, value|
      path = key.split(".")
      current_value = spec_body.dig(*path)
      new_value = flex_params[key]
      if is_flex_id(current_value) && is_valid_id(new_value)
        assign_nested_value(spec_body, path, new_value)
      end
    end

    spec_body
  end

  def verify_response(response, flex_params = [])
    spec_status = spec["response"]["status"].to_i
    spec_body = spec["response"]["body"].deep_dup

    flex_params.each do |key|
      path = key.split(".")
      current_value = spec_body.dig(*path)
      new_value = response.dig(*path)
      if is_flex_id(current_value) && is_valid_id(new_value)
        assign_nested_value(spec_body, path, new_value)
      end
    end

    if response["data"]
      spec_body["data"]["relationships"] = response["data"]["relationships"]
    end

    yield spec_status, spec_body
  end

  private

  def load_api_fixture(path)
    full_path = Rails.root.join("spec", "fixtures", "api", "#{path}.json")
    JSON.parse(File.read(full_path))
  end

  def is_flex_id(value)
    value == "@id"
  end

  def is_valid_id(value)
    value.present?
  end

  def assign_nested_value(hash, path, new_value)
    *remainder, tail = path
    remainder.inject(hash, :fetch)[tail] = new_value
  end
end
