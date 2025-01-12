require "./spec_helper"

describe App::OAuth do
  client = AC::SpecHelper.client

  # optional, use to change the response type
  headers = HTTP::Headers{
    "Accept" => "application/json",
  }

  it "should generate a date string" do
    # instantiate the controller you wish to unit test
    oauth = App::OAuth.spec_instance(HTTP::Request.new("GET", "/authorize"))

    # Test the instance methods of the controller
    oauth.set_date_header.should contain("GMT")
  end

  it "should return bad request on authorizing with invalid params" do
    result = client.get("/oauth/authorize")
    result.body.should eq "{\"error\":\"Only 'code' is supported as response_type\"}"
    result.status_code.should eq 400
  end
end
