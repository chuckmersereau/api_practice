# remove this if Rails is >= 4.2.1
# http://apidock.com/rails/v4.2.1/Hash/transform_values

class Hash
  def transform_values
    return enum_for(:transform_values) unless block_given?

    result = self.class.new
    each do |key, value|
      result[key] = yield(value)
    end

    result
  end
end
