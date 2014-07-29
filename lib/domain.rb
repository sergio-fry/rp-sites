class Domain
  def initialize(domain)
    @domain = domain.strip
  end

  def level
    domain_without_www.split(".").size
  end

  def parent
    if level > 2
      parts = @domain.split(".")
      parts.shift

      Domain.new(parts.join("."))
    end
  end

  def domain_without_www
    @domain.sub(/^www\./, "")
  end

  def to_s
    @domain
  end
end
