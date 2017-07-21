require "spec_helper"

RSpec.describe ApiValidator do
  it "has a version number" do
    expect(ApiValidator::VERSION).not_to be nil
  end

  let(:api_validator) { ApiValidator.new(fixture: fixture) }

  describe "#build_request" do
    let(:fixture) do
      {
        "request" => {
          "body" => {
            "foo" => "bar",
            "outer" => {
              "inner" => inner_value
            }
          }
        }
      }
    end

    context "with no flex params in fixture" do
      let(:inner_value) { "dolphin" }

      it "returns the fixture with no changes" do
        expect(api_validator.build_request).to eq(fixture["request"]["body"])
      end
    end

    context "with @id flex param in fixture" do
      let(:inner_value) { "@id" }

      it "returns the fixture with replaced value" do
        request = api_validator.build_request({
          "outer.inner" => "123"
        })
        expected_request = {
          "foo" => "bar",
          "outer" => {
            "inner" => "123"
          }
        }
        expect(request).to eq(expected_request)
      end
    end
  end

  describe "#verify_response" do
    let(:fixture) do
      {
        "response" => {
          "body" => {
            "foo" => "bar",
            "outer" => {
              "inner" => inner_value
            }
          },
          "status" => "200"
        }
      }
    end

    context "with no flex params in fixture" do
      let(:inner_value) { "dolphin" }

      it "returns the fixture with no changes" do
        api_validator.verify_response(fixture) do |status, body|
          expect(status).to eq(200)
          expect(body).to eq(fixture["response"]["body"])
        end
      end
    end

    context "with @id flex param in fixture" do
      let(:inner_value) { "@id" }

      it "returns the fixture with replaced value" do
        response = {
          "foo" => "bar",
          "outer" => {
            "inner" => "123"
          }
        }
        api_validator.verify_response(response, ["outer.inner"]) do |status, body|
          expect(status).to eq(200)
          expect(body).to eq(response)
        end
      end
    end
  end
end
