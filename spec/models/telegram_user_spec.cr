require "../spec_helper"
require "jwt"

def secret
  "superSafe" * 4
end

def build_user(hash)
  user = App::TelegramUser.new(id: hash["id"].not_nil!.to_i64, username: hash["username"].to_s)
  user.first_name = hash["first_name"]?
  user.last_name = hash["last_name"]?
  user.photo_url = hash["photo_url"]?
  user.auth_date = hash["auth_date"]?.try &.to_i64
  user
end

describe App::TelegramUser do
  it "builds and decodes access token" do
    auth_date = Time.utc.to_unix
    tg_user = build_user({
      "id"         => "33333333",
      "username"   => "pinokkio",
      "first_name" => "pinokkio",
      "last_name"  => nil,
      "photo_url"  => "https://t.me/i/userpic/320/ubtf_8oAh2RPz9t-9WdiqOD9p8SreANNDM4RSY8l95o.jpg",
      "auth_date"  => auth_date.to_s,
    })
    access_token = tg_user.access_token(secret: secret)
    access_token.should be_a(String)

    decoded_tg_user = App::TelegramUser.from_token(access_token, secret: secret)
    decoded_tg_user.id.should eq 33333333
    decoded_tg_user.first_name.should eq("pinokkio")
    decoded_tg_user.last_name.should be_nil
    decoded_tg_user.username.should eq("pinokkio")
    decoded_tg_user.photo_url.should eq("https://t.me/i/userpic/320/ubtf_8oAh2RPz9t-9WdiqOD9p8SreANNDM4RSY8l95o.jpg")
    decoded_tg_user.auth_date.should eq(auth_date)
    decoded_tg_user.telegram_email.should eq("33333333+oauth_bot@t.me")
  end

  it "builds and decodes access token with empty params" do
    tg_user = build_user({
      "id"       => "33333333",
      "username" => "pinokkio",
    })
    access_token = tg_user.access_token(secret: secret)
    access_token.should be_a(String)

    decoded_tg_user = App::TelegramUser.from_token(access_token, secret: secret)
    decoded_tg_user.id.should eq 33333333
    decoded_tg_user.first_name.should be_nil
    decoded_tg_user.last_name.should be_nil
    decoded_tg_user.username.should eq("pinokkio")
    decoded_tg_user.photo_url.should be_nil
    decoded_tg_user.auth_date.should be_nil
    decoded_tg_user.telegram_email.should eq("33333333+oauth_bot@t.me")
  end

  it "builds and decodes auth code" do
    auth_date = Time.utc.to_unix
    tg_user = build_user({
      "id"        => "33333333",
      "username"  => "pinokkio",
      "auth_date" => auth_date.to_s,
    })
    auth_code = tg_user.auth_code(secret: secret)
    auth_code.should be_a(String)

    decoded_tg_user = App::TelegramUser.from_token(auth_code, secret: secret)
    decoded_tg_user.id.should eq 33333333
    decoded_tg_user.first_name.should be_nil
    decoded_tg_user.last_name.should be_nil
    decoded_tg_user.username.should eq("pinokkio")
    decoded_tg_user.photo_url.should be_nil
    decoded_tg_user.auth_date.should eq(auth_date)
    decoded_tg_user.telegram_email.should eq("33333333+oauth_bot@t.me")
  end

  it "builds payload hash" do
    auth_date = Time.utc.to_unix
    tg_user = build_user({
      "id"        => "33333333",
      "username"  => "pinokkio",
      "auth_date" => auth_date.to_s,
    })

    tg_user.payload.should eq(
      {
        "sub"         => 33333333,
        "name"        => "pinokkio",
        "given_name"  => nil,
        "family_name" => nil,
        "picture"     => nil,
        "auth_date"   => auth_date,
      }
    )
  end

  it "builds user profile data" do
    auth_date = Time.utc.to_unix
    tg_user = build_user({
      "id"         => "33333333",
      "username"   => "pinokkio",
      "first_name" => "pinokkio",
      "last_name"  => nil,
      "photo_url"  => "https://t.me/i/userpic/320/ubtf_8oAh2RPz9t-9WdiqOD9p8SreANNDM4RSY8l95o.jpg",
      "auth_date"  => auth_date.to_s,
    })

    tg_user.profile_data.should eq(
      {
        "sub"         => 33333333,
        "name"        => "pinokkio",
        "given_name"  => "pinokkio",
        "family_name" => nil,
        "picture"     => "https://t.me/i/userpic/320/ubtf_8oAh2RPz9t-9WdiqOD9p8SreANNDM4RSY8l95o.jpg",
        "auth_date"   => auth_date,
        "email"       => "33333333+oauth_bot@t.me",
      }
    )
  end
end
