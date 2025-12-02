#!/usr/bin/env ruby
# frozen_string_literal: true

require 'cgi'
require_relative '../lib/rss_reader'

def show(val, max=20)
  str = val.to_s
  str = CGI.unescapeHTML(str)
  str.length > max*2 ? "#{str[0...max]}...#{str[-max..-1]}" : str
end

reader = RSSReader.new('feeds.json')
puts "Loaded #{reader.load_feeds.size} feeds."

items = reader.items_from_all_feeds
puts "Fetched #{items.size} items.\n\n"

items.each_with_index do |item, i|
  puts "Item ##{i+1}"
  item.each { |k,v| puts "#{k.to_s.ljust(10)}: #{show(v)}" }
  puts "-" * 50
end
