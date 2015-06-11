class Encryptor
  def initialize(default = nil)
    @default = default
  end

  def cipher
    @cipher ||= ::Gibberish::AES.new(ENV.fetch('ENCRYPTION_KEY'))
  end

  def load(s)
    s.present? ? cipher.dec(s) : @default
  end

  def dump(s)
    if val = (s || @default)
      cipher.enc(val)
    end
  end
end
