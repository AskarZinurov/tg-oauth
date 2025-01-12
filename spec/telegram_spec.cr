require "./spec_helper"

describe App::Telegram do
  client = AC::SpecHelper.client

  # optional, use to change the response type
  headers = HTTP::Headers{
    "Accept" => "text/html",
  }

  it "should generate a date string" do
    # instantiate the controller you wish to unit test
    oauth = App::Telegram.spec_instance(HTTP::Request.new("GET", "/healthcheck"))

    # Test the instance methods of the controller
    oauth.set_date_header.should contain("GMT")
  end

  it "should return heartbeat response" do
    result = client.get("/healthcheck")
    result.body.should eq %("OK")
  end

  it "should render telegram login button" do
    result = client.get("/")
    result.body.should contain("<script async src=\"https://telegram.org/js/telegram-widget.js?22\"")
    result.body.should contain("data-auth-url=\"http://localdomain.localhost/callback\"")
    result.status_code.should eq 200
  end

  it "should fail callback response on wrong params" do
    result = client.get("/callback")
    result.status_code.should eq 400
  end

  it "should redirect back with auth_code" do
    auth_result = client.get("/oauth/authorize?response_type=code&scope=openid%20email%20profile&" \
      "client_id=zitadel&redirect_uri=http%3A%2F%2Fzitadel.localhost&state=auth")
    cookie = auth_result.headers["Set-Cookie"]
    cookie = cookie.split("%3B")[0]
    auth_date = 5.minutes.ago.to_unix

    digest = OpenSSL::Digest.new("SHA256")
    digest << ENV["TELEGRAM_TOKEN"]

    callback_data = <<-DATA
auth_date=#{auth_date}
first_name=frederico
id=123123123
last_name=garibaldi
photo_url=
username=frederico
DATA
    hash = OpenSSL::HMAC.hexdigest(OpenSSL::Algorithm::SHA256, digest.final, callback_data)

    result = client.get("/callback?hash=#{hash}&id=123123123&username=frederico&first_name=frederico&" \
      "last_name=garibaldi&photo_url=&auth_date=#{auth_date}", headers: HTTP::Headers{"Cookie" => cookie})
    result.status_code.should eq 302
    result.headers["Location"].should contain("http://zitadel.localhost?")
  end
end
