class SecurIDService
  def initialize(username, options={})
    options[:test_mode] = ENV['SECURID_TEST_MODE'].to_sym if !options.has_key?(:test_mode) && ENV['SECURID_TEST_MODE']
    @username = username
    @session = RSA::SecurID::Session.new options
  end

  # These could pretty much all be method_missing forwards, but the verbosity here helps
  # with comprehension.

  def authenticate(pin, token)
    validate_token(token)
    validate_pin(pin)

    @session.authenticate(@username, pin.to_s + token.to_s)
  end

  def change_pin(pin)
    validate_pin(pin)

    @session.change_pin(pin)
  end

  def cancel_pin
    @session.cancel_pin
  end

  def resynchronize(pin, token)
    validate_token(token)
    validate_pin(pin)

    @session.resynchronize(pin.to_s + token.to_s)
  end

  def status
    @session.status
  end

  def resynchronize?
    @session.resynchronize?
  end

  def change_pin?
    @session.change_pin?
  end

  def authenticated?
    @session.authenticated?
  end

  def denied?
    @session.denied?
  end

  class InvalidToken < ArgumentError; end;
  class InvalidPin < ArgumentError; end;

  private

  def validate_token(token)
    raise InvalidToken, 'token must be 6 digits' if !token.match /\A\d{6}\z/
  end

  def validate_pin(pin)
    raise InvalidPin, 'pin must be 4 digits' if !pin.match /\A\d{4}\z/
  end
end