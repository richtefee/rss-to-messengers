# rss_reader.rb
require 'json'
require 'net/http'
require 'uri'
require 'nokogiri'
require 'date'

class RSSReader
    def initialize(feedfile)
        @feedfile = feedfile
    end

    def load_feeds
        JSON.parse(File.read(@feedfile))
    end

    def fetch_feed(url)
        uri = URI(url)
        resp = Net::HTTP.get_response(uri)
        return nil unless resp.is_a?(Net::HTTPSuccess)
        Nokogiri::XML(resp.body)
    rescue StandardError => e
        warn "RSS fetch error #{url}: #{e.message}"
        nil
    end

    def extract_items(doc, feed_name)
        return [] unless doc

        items = []

        doc.css('item, entry').each do |node|
            guid = node.css('guid, id').text.strip
            next if guid.empty?

            title = node.css('title').text.strip

            link = node.css('link').text.strip
            link = node.css('link').first['href'] if link.empty? && node.css('link').first
            link = guid if link.empty?

            date_str = node.css('pubDate, published').text.strip
            begin
                pub_date = DateTime.parse(date_str)
            rescue StandardError
                next
            end

            # Extract summary/description
            summary = node.css('description, summary').text.strip
            summary = nil if summary.empty?

            items << {
                guid: guid,
                title: title,
                link: link,
                pub_date: pub_date,
                feed_name: feed_name,
                summary: summary
            }
        end

        items
    end

    def items_from_all_feeds
        all = []
        load_feeds.each do |feed|
            doc = fetch_feed(feed["url"])
            all.concat(extract_items(doc, feed["name"]))
        end
        all
    end
end
