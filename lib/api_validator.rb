require "api_validator/version"
require "active_support/all"

class ApiValidator
  attr_reader :spec

  def initialize(options)
    path = options[:fixture_path]
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

  def verify_response(response_input, flex_params = [])
    spec_status = spec["response"]["status"].to_i
    spec_body = spec["response"]["body"].deep_dup
    response = response_input.deep_dup

    flex_params.each do |key|
      path = key.split(".")
      current_value = spec_body.dig(*path)
      new_value = response.dig(*path)
      if is_flex_id(current_value) && is_valid_id(new_value)
        assign_nested_value(spec_body, path, new_value)
      end
    end

    copy_id(response["data"], spec_body["data"])
    copy_links(response["data"], spec_body["data"])
    copy_relationships(response["data"], spec_body["data"])
    copy_timestamps(response["data"], spec_body["data"])

    response_included = response["included"] || []
    spec_body_included = spec_body["included"] || []
    response_included.each_with_index do |reponse_included_item, index|
      if spec_body_included[index]
        copy_id(reponse_included_item, spec_body_included[index])
        copy_links(reponse_included_item, spec_body_included[index])
        copy_relationships(reponse_included_item, spec_body_included[index])
        copy_timestamps(reponse_included_item, spec_body_included[index])
      end
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

  def copy_relationships(source, target)
    if source && source["relationships"] && target
      target["relationships"] = source["relationships"]
    end
  end

  def copy_links(source, target)
    if source && source["links"] && target
      target["links"] = source["links"]
    end
  end

  def copy_timestamps(source, target)
    if source && target && target["attributes"]
      if source.dig("attributes", "created-at")
        if timestamp_is_valid?(source["attributes"]["created-at"])
          target["attributes"]["created-at"] = source["attributes"]["created-at"]
        end
      end

      if source.dig("attributes", "updated-at")
        if timestamp_is_valid?(source["attributes"]["updated-at"])
          target["attributes"]["updated-at"] = source["attributes"]["updated-at"]
        end
      end
    end
  end

  def copy_id(source, target)
    if source && target
      if id_is_valid?(source["id"])
        target["id"] = source["id"]
      end
    end
  end

  def timestamp_is_valid?(str)
    is_valid = true
    begin
      DateTime.parse str
    rescue ArgumentError
      is_valid = false
    end
    is_valid
  end

  def id_is_valid?(str)
    str.present?
  end
end
