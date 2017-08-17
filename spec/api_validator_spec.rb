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

    context "with id flex param in fixture" do
      let(:inner_value) { "id\#inner-value" }

      it "returns the fixture with replaced value" do
        request = api_validator.build_request({
          "inner-value" => "123"
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
        response = fixture["response"]["body"]
        api_validator.verify_response(response) do |status, body|
          expect(status).to eq(200)
          expect(body).to eq(response)
        end
      end
    end

    context "with id flex param in fixture" do
      let(:inner_value) { "id\#inner_value" }

      it "returns the fixture with replaced value" do
        response = {
          "foo" => "bar",
          "outer" => {
            "inner" => "123"
          }
        }
        api_validator.verify_response(response, { "inner_value" => "123" }) do |status, body|
          expect(status).to eq(200)
          expect(body).to eq(response)
        end
      end
    end

    context "with different timestamps in response and fixture" do
      let(:fixture) do
        {
          "response" => {
            "body" => {
              "foo" => "bar",
              "data" => {
                "attributes" => {
                  "created-at" => "2017-08-10T05:16:27.707Z",
                  "updated-at" => "2017-08-10T05:16:27.707Z"
                }
              },
              "included" => [
                {
                  "id" => "9",
                  "attributes" => {
                    "created-at" => "2017-08-10T05:16:27.707Z",
                    "updated-at" => "2017-08-10T05:16:27.707Z"
                  }
                }
              ]
            },
            "status" => "200"
          }
        }
      end

      let(:response) do
        {
          "foo" => "bar",
          "data" => {
            "attributes" => {
              "created-at" => "2017-08-10T05:43:48.266Z",
              "updated-at" => "2017-08-10T05:43:48.266Z"
            }
          },
          "included" => [
            {
              "id" => "9",
              "attributes" => {
                "created-at" => "2017-08-10T05:43:48.266Z",
                "updated-at" => "2017-08-10T05:43:48.266Z"
              }
            }
          ]
        }
      end

      it "can still verify the response" do
        api_validator.verify_response(response) do |status, body|
          expect(status).to eq(200)
          expect(body).to eq(response)
        end
      end
    end

    context "with invalid timestamp in response" do
      let(:fixture) do
        {
          "response" => {
            "body" => {
              "foo" => "bar",
              "data" => {
                "attributes" => {
                  "created-at" => "2017-08-10T05:43:48.266Z",
                  "updated-at" => "2017-08-10T05:43:48.266Z"
                }
              }
            },
            "status" => "200"
          }
        }
      end

      let(:response) do
        {
          "foo" => "bar",
          "data" => {
            "attributes" => {
              "created-at" => "asdf",
              "updated-at" => "asdf"
            }
          }
        }
      end

      it "does not verify the response" do
        api_validator.verify_response(response) do |status, body|
          expect(body).not_to eq(response)
        end
      end
    end

    context "with links in response but not fixture" do
      let(:response) do
        {
          "data" => {
            "id" => "123",
            "type" => "orders",
            "links" => {
              "self" => "http://www.example.com/api/orders/123"
            },
            "relationships" => {
              "credit-card" => {
                "links" => {
                  "self" => "http://www.example.com/api/orders/123/relationships/credit-card",
                  "related" => "http://www.example.com/api/orders/123/credit-card"
                }
              }
            }
          },
          "included" => [
            {
              "id" => "9",
              "type" => "credit-cards",
              "links" => {
                "self" => "http://www.example.com/api/credit-cards/9"
              },
              "relationships" => {
                "whatever" => {
                  "links" => {
                    "self" => "http://www.example.com/api/orders/123/relationships/whatever",
                    "related" => "http://www.example.com/api/orders/123/whatever"
                  }
                }
              }
            },
            {
              "id" => "5",
              "type" => "credit-cards",
              "links" => {
                "self" => "http://www.example.com/api/credit-cards/5"
              }
            }
          ]
        }
      end

      let(:fixture) do
        {
          "response" => {
            "body" => {
              "data" => {
                "id" => "123",
                "type" => "orders",
                "relationships" => {
                  "credit-card" => {}
                }
              },
              "included" => [
                {
                  "id" => "9",
                  "type" => "credit-cards",
                  "relationships" => {
                    "whatever" => {}
                  }
                },
                {
                  "id" => "5",
                  "type" => "credit-cards"
                }
              ]
            },
            "status" => "200"
          }
        }
      end

      it "can still verify the response" do
        api_validator.verify_response(response) do |status, body|
          expect(body).to eq(response)
        end
      end
    end

    context "with different ids in response and fixture" do
      let(:fixture) do
        {
          "response" => {
            "body" => {
              "foo" => "bar",
              "data" => {
                "id" => "123",
                "relationships" => {
                  "credit-card" => {
                    "id" => "123"
                  }
                }
              },
              "included" => [
                {
                  "id" => "123",
                  "relationships" => {
                    "credit-card" => {
                      "id" => "123"
                    }
                  }
                }
              ]
            },
            "status" => "200"
          }
        }
      end

      let(:response) do
        {
          "foo" => "bar",
          "data" => {
            "id" => "567",
            "relationships" => {
              "credit-card" => {
                "id" => "567"
              }
            }
          },
          "included" => [
            {
              "id" => "567",
              "relationships" => {
                "credit-card" => {
                  "id" => "567"
                }
              }
            }
          ]
        }
      end

      it "can still verify the response" do
        api_validator.verify_response(response) do |status, body|
          expect(status).to eq(200)
          expect(body).to eq(response)
        end
      end
    end
  end
end
