require 'nokogiri'
require 'charlock_holmes'
require 'date'

class SiteWorker
  include Celluloid
  include Celluloid::IO

  def fetch_title(site_id)
    site = Site.find(site_id)
    puts "Fetch title of site #{site[:domain]}..."

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
    else
      puts "Fetch title of site #{site[:domain]}... Up to date!"
    end
  end

  def fetch_alexa_rank(site_id)
    site = Site.find(site_id)

    checked_at = DateTime.parse(site["alexa_rank_checked_at"]) rescue nil

    puts "Update Alexa rang of #{site['domain']}.."

    if checked_at.nil? || checked_at < 7.days.ago

      site["alexa_rank"] = alexa_rank(site[:domain])

      site["alexa_rank_checked_at"] = Time.now.to_s

      site.save
    else
      puts "Update Alexa rang of #{site["domain"]}. Up to date!"
    end
  end


  def fetch_cy(site_id)
    site = Site.find(site_id)

    checked_at = DateTime.parse(site["cy_checked_at"]) rescue nil

    puts "Update CY of #{site['domain']}.."

    if checked_at.nil? || checked_at < 7.days.ago
      xml = open("http://bar-navig.yandex.ru/u?show=31&url=http://#{site[:domain]}").read

      doc = Nokogiri::XML(xml)

      begin
        site["cy"] = doc.css("tcy")[0].attributes["value"].value.to_i
      rescue StandardError => ex
        puts xml rescue nil
        puts ex.to_s
      end

      site["cy_checked_at"] = Time.now.to_s

      site.save
    else
      puts "Update CY of #{site["domain"]}. Up to date!"
    end
  end

  private

  def alexa_rank(domain)

    xml = open("http://data.alexa.com/data?cli=10&url=#{domain}").read

    doc = Nokogiri::XML(xml)

    rank = nil

    begin
      rank = doc.css("REACH")[0].attributes["RANK"].value.to_i
    rescue StandardError => ex
      puts xml rescue nil
      puts ex.to_s
    end

    parent_domain = Domain.new(domain).parent

    unless parent_domain.nil?
      parent_rank = alexa_rank(parent_domain.to_s)

      # Если Alexa не отличает домен от его родителя, то rank = nil
      if parent_rank == rank
        rank = nil
      end
    end

    puts "Alexa rank #{domain} = #{rank || "NULL"}"

    rank
  end

end
