require "action-controller/logger"
require "lucky_env"

LuckyEnv.load?(".env")

module App
  NAME = "OAUTH Telegram"
  {% begin %}
    VERSION = {{ `shards version "#{__DIR__}"`.chomp.stringify.downcase }}
  {% end %}

  ENVIRONMENT   = ENV["APP_ENV"]? || "development"
  IS_PRODUCTION = ENVIRONMENT == "production"

  def self.production?
    IS_PRODUCTION
  end

  Log         = ::Log.for(NAME)
  LOG_BACKEND = ActionController.default_backend(
    formatter: production? ? ActionController.json_formatter : ActionController.default_formatter
  )

  DEFAULT_PORT          = (ENV["APP_PORT"]? || 3000).to_i
  DEFAULT_HOST          = ENV["APP_HOST"]? || "127.0.0.1"
  DEFAULT_PROCESS_COUNT = (ENV["APP_PROCESS_COUNT"]? || 1).to_i
  APP_PROTOCOL          = ENV["APP_PROTOCOL"]? || "http"
  APP_DOMAIN            = ENV["APP_DOMAIN"]? || DEFAULT_HOST

  TELEGRAM_TOKEN          = ENV["TELEGRAM_TOKEN"]
  TELEGRAM_BOT            = ENV["TELEGRAM_BOT"]
  JWT_SECRET              = ENV["JWT_SECRET"]
  OAUTH_CLIENT_ID         = ENV["OAUTH_CLIENT_ID"]
  OAUTH_CLIENT_SECRET     = ENV["OAUTH_CLIENT_SECRET"]
  OAUTH_REDIRECT_URIS     = ENV["OAUTH_REDIRECT_URIS"].split(' ')
  ACCESS_TOKEN_EXPIRES_IN = 24.hours
  AUTH_CODE_EXPIRES_IN    = 5.minutes

  STATIC_FILE_PATH = ENV["PUBLIC_WWW_PATH"]? || "./www"

  COOKIE_SESSION_KEY    = ENV["COOKIE_SESSION_KEY"]? || "tg_oauth"
  COOKIE_SESSION_SECRET = ENV["COOKIE_SESSION_SECRET"]

  # flag to indicate if we're outputting trace logs
  class_getter? trace : Bool = false

  # Registers callbacks for USR1 signal
  #
  # **`USR1`**
  # toggles `:trace` for _all_ `Log` instances
  # `namespaces`'s `Log`s to `:info` if `production` is `true`,
  # otherwise it is set to `:debug`.
  # `Log`'s not registered under `namespaces` are toggled to `default`
  #
  # ## Usage
  # - `$ kill -USR1 ${the_application_pid}`
  def self.register_severity_switch_signals : Nil
    # Allow signals to change the log level at run-time
    {% unless flag?(:win32) %}
      Signal::USR1.trap do |signal|
        @@trace = !@@trace
        level = @@trace ? ::Log::Severity::Trace : (production? ? ::Log::Severity::Info : ::Log::Severity::Debug)
        puts " > Log level changed to #{level}"
        ::Log.builder.bind "#{NAME}.*", level, LOG_BACKEND

        # Ignore standard behaviour of the signal
        signal.ignore

        # we need to re-register our interest in the signal
        register_severity_switch_signals
      end
    {% end %}
  end
end
