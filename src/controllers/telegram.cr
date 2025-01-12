require "openssl/hmac"

class App::Telegram < App::Base
  layout "telegram.ecr"

  DIGEST_KEY = "hash"

  base "/"

  @[AC::Route::GET("/")]
  def index
    telegram_bot = App::TELEGRAM_BOT
    callback_url = "#{App::APP_PROTOCOL}://#{App::APP_DOMAIN}/callback"

    render template: "telegram/index.ecr"
  end

  @[AC::Route::GET("/callback")]
  def callback
    if digest_valid?(params.to_h)
      if Time.utc - Time::UNIX_EPOCH - Time::Span.new(seconds: params["auth_date"].to_i) > Time::Span.new(hours: 24)
        raise Error::BadRequest.new("Invalid callback data")
      end
      state = session["state"]
      redirect_uri = session["redirect_uri"]
      raise Error::BadRequest.new("Broken authorization sequence") if state.nil? || redirect_uri.nil?

      url = URI.parse(redirect_uri.to_s)
      query_params = url.query_params.tap do |qp|
        qp["state"] = state.to_s
        qp["code"] = App::TelegramUser.from_params(params).auth_code
      end
      url.query_params = query_params

      redirect_to url.to_s
    else
      raise Error::BadRequest.new("Invalid callback data")
    end
  end

  @[AC::Route::GET("/healthcheck")]
  def healthcheck
    "OK"
  end

  private def digest_for(params, secret = App::TELEGRAM_TOKEN)
    signature = params.keys.reject(DIGEST_KEY).map do |key|
      "#{key}=#{params[key]}" if params.has_key?(key)
    end.compact.sort.join("\n")

    digest = OpenSSL::Digest.new("SHA256")
    digest << secret

    OpenSSL::HMAC.hexdigest(OpenSSL::Algorithm::SHA256, digest.final, signature)
  end

  private def digest_valid?(params, secret = App::TELEGRAM_TOKEN)
    params.has_key?(DIGEST_KEY) && digest_for(params, secret) == params[DIGEST_KEY]
  end
end
