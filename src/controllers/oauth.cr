class App::OAuth < App::Base
  base "oauth"

  @[AC::Route::GET("/authorize")]
  def authorize(
    state : String?,
    redirect_uri : String?,
    response_type : String?,
    client_id : String?,
    scope : String?
  )
    if response_type != "code"
      raise Error::BadRequest.new("Only 'code' is supported as response_type")
    end

    check_redirect_uri!(redirect_uri)
    check_client_id!(client_id)

    session["state"] = state
    session["redirect_uri"] = redirect_uri
    session["scope"] = scope

    redirect_to Telegram.index
  end

  @[AC::Route::POST("/token")]
  def token
    raise Error::BadRequest.new("Missing code params") unless params.has_key?("code")
    check_redirect_uri!(params["redirect_uri"]?)
    check_client_id!(params["client_id"]?)

    if params["client_secret"] != App::OAUTH_CLIENT_SECRET
      raise Error::BadRequest.new("Invalid client secret")
    end

    if params["grant_type"]? != "authorization_code"
      raise Error::BadRequest.new("Only 'authorization_code' is supported as grant_type")
    end

    telegram_user = TelegramUser.from_token(params["code"])

    {
      access_token: telegram_user.access_token,
      token_type:   "Bearer",
      expires_in:   App::ACCESS_TOKEN_EXPIRES_IN.to_i,
    }
  end

  @[AC::Route::GET("/profile")]
  def profile
    token = acquire_token
    raise Error::BadRequest.new("Access token missing") if token.nil?
    telegram_user = TelegramUser.from_token(token.not_nil!)
    telegram_user.profile_data
  end

  private def check_client_id!(client_id)
    if App::OAUTH_CLIENT_ID != client_id
      raise Error::BadRequest.new("Invalid 'client_id'")
    end
  end

  private def check_redirect_uri!(uri : String?)
    if uri.nil? || !App::OAUTH_REDIRECT_URIS.includes?(uri)
      raise Error::BadRequest.new("Invalid redirect URI")
    end
  end

  protected def acquire_token : String?
    if token = request.headers["Authorization"]?
      token = token.lchop("Bearer ").lchop("Token ").rstrip
      token unless token.empty?
    end
  end
end
