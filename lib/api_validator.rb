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
    spec_body = replace_flex_params(spec_body, flex_params)
    spec_body
  end

  def verify_response(response_input, flex_params = [])
    spec_status = spec["response"]["status"].to_i
    spec_body = spec["response"]["body"].deep_dup
    spec_body = replace_flex_params(spec_body, flex_params)
    response = response_input.deep_dup
    copy_links(response, spec_body)

    # The `data` attribute can be either a single resource, or a list of resources
    if response["data"].kind_of?(Array)
      response["data"].each_with_index do |item, index|
        if spec_body["data"][index]
          copy_values(item, spec_body["data"][index])
        end
      end
    else
      copy_values(response["data"], spec_body["data"])
    end

    response_included = response["included"] || []
    spec_body_included = spec_body["included"] || []
    response_included.each_with_index do |reponse_included_item, index|
      if spec_body_included[index]
        copy_values(reponse_included_item, spec_body_included[index])
      end
    end

    yield spec_status, spec_body
  end

  private

  def load_api_fixture(path)
    full_path = Rails.root.join("spec", "fixtures", "api", "#{path}.json")
    JSON.parse(File.read(full_path))
  end

  def replace_flex_params(json, flex_params)
    stringified = JSON.generate(json)
    flex_params.each do |param, value|
      if (stringified.include?(param_as_id(param)) && is_valid_id(value))
        stringified.gsub!(param_as_id(param), value.to_s)
      elsif (stringified.include?(param_as_number(param)) && is_valid_number(value))
        stringified.gsub!(param_as_number(param), "#{value.to_s}")
      elsif (stringified.include?(param_as_any(param)))
        stringified.gsub!(param_as_any(param), "\"#{value.to_s}\"")
      end
    end
    JSON.parse(stringified)
  end

  def param_as_id(param)
    "\"id\##{param}\""
  end

  def param_as_number(param)
    "\"number\##{param}\""
  end

  def is_valid_id(value)
    value.present?
  end

  def is_valid_number(value)
    value.is_a? Numeric
  end

  def param_as_any(param)
    "\"any\##{param}\""
  end

  def copy_values(source, target)
    copy_id(source, target)
    copy_links(source, target)
    copy_relationships(source, target)
    copy_timestamps(source, target)
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
