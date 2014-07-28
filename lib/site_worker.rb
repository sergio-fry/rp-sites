require 'nokogiri'
require 'charlock_holmes'
require 'date'

class SiteWorker
  include Celluloid
  include Celluloid::IO

  def fetch_title(site_id)
    site = Site.find(site_id)

    checked_at = DateTime.parse(site["title_checked_at"]) rescue nil

    if checked_at.nil? || checked_at < 3.days.ago
      begin
        html = open("http://#{site["domain"]}").read
        detection = CharlockHolmes::EncodingDetector.detect(html)
        encoding = detection[:encoding] || "UTF-8"

        doc = Nokogiri::HTML(html, encoding)

        site["title"] = doc.css("title").text

      rescue StandardError => ex
        puts html rescue nil
        puts ex.to_s
      end

      site["title_checked_at"] = Time.now.to_s

      site.save
    end
  end

  def fetch_alexa_rank(site_id)
    site = Site.find(site_id)

    checked_at = DateTime.parse(site["alexa_rank_checked_at"]) rescue nil

    puts "Update Alexa rang of #{site['domain']}.."

    if checked_at.nil? || checked_at < 7.days.ago
      xml = open("http://data.alexa.com/data?cli=10&url=#{site["domain"]}").read

      doc = Nokogiri::XML(xml)

      begin
        site["alexa_rank"] = doc.css("REACH")[0].attributes["RANK"].value.to_i
      rescue StandardError => ex
        puts xml rescue nil
        puts ex.to_s
      end

      site["alexa_rank_checked_at"] = Time.now.to_s

      site.save
    else
      puts "Update Alexa rang of #{site["domain"]}. Up to date!"
    end
  end
end
