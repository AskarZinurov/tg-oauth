require "jwt"

class App::TelegramUser
  property id : Int64
  property username : String
  property first_name : String?
  property last_name : String?
  property photo_url : String?
  property auth_date : Int64?

  def initialize(@id, @username)
  end

  def payload
    {
      "sub"         => id,
      "name"        => username,
      "given_name"  => first_name,
      "family_name" => last_name,
      "picture"     => photo_url,
      "auth_date"   => auth_date,
    }
  end

  def profile_data
    payload.tap do |payload|
      payload["email"] = telegram_email
    end
  end

  def auth_code(exp = (Time.utc + App::AUTH_CODE_EXPIRES_IN).to_unix, secret = App::JWT_SECRET)
    JWT.encode(
      {"user_id" => id, "type" => "auth_code", "exp" => exp, "user_data" => payload.to_json},
      secret,
      JWT::Algorithm::HS256
    )
  end

  def access_token(exp = (Time.utc + App::ACCESS_TOKEN_EXPIRES_IN).to_unix, secret = App::JWT_SECRET)
    JWT.encode(
      {"user_id" => id, "type" => "access_token", "exp" => exp, "user_data" => payload.to_json},
      secret,
      JWT::Algorithm::HS256
    )
  end

  def telegram_email
    "#{id}+#{App::TELEGRAM_BOT}@t.me"
  end

  def self.from_token(token : String, secret = App::JWT_SECRET) : TelegramUser
    payload, header = JWT.decode(token, secret, JWT::Algorithm::HS256)
    user_data = JSON.parse(payload["user_data"].as_s).as_h

    new(id: user_data["sub"].as_i64, username: user_data["name"].as_s).tap do |user|
      user.first_name = user_data["given_name"]?.try &.as_s?
      user.last_name = user_data["family_name"]?.try &.as_s?
      user.photo_url = user_data["picture"]?.try &.as_s?
      user.auth_date = user_data["auth_date"]?.try &.as_i64?
    end
  end

  def self.from_params(hash)
    user = TelegramUser.new(id: hash["id"].to_i64, username: hash["username"])
    user.first_name = hash["first_name"]?
    user.last_name = hash["last_name"]?
    user.photo_url = hash["photo_url"]?
    user.auth_date = hash["auth_date"]?.try &.to_i64
    user
  end
end
