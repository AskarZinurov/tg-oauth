class Error < Exception
  getter message

  def initialize(@message : String = "")
    super(message)
  end

  class BadRequest < Error
  end
end
