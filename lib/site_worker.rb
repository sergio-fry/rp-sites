require 'nokogiri'

class SiteWorker
  include Celluloid
  include Celluloid::IO

  def fetch_title(site_id)
    site = Site.find(site_id)

    doc = Nokogiri::HTML(open("http://#{site["domain"]}"))

    site["title"] = doc.css("title").text

    site.save
  end
end
