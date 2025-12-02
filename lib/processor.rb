# lib/processor.rb
# frozen_string_literal: true

require 'dotenv/load'
require_relative 'rss_reader'
require_relative 'message_builder'
require_relative 'messengers'

class Processor
    def initialize(feeds_file:, messengers:, message_config:)
        @feeds_file = feeds_file
        @messengers = messengers
        @message_config = message_config
        @reader = RSSReader.new(feeds_file)
        @builder = MessageBuilder.new(
            header: message_config[:header],
            footer: message_config[:footer]
        )
    end

    def run
        puts "Loading feeds from #{@feeds_file}..."
        items = @reader.items_from_all_feeds
        puts "Fetched #{items.size} items."

        # Filter items that are not yet sent for any messenger
        unsent_items = items.reject do |item|
            @messengers.all? { |m| m.seen?(item[:guid]) }
        end

        if unsent_items.empty?
            puts "No new items to send."
            return
        end

        # Pick the oldest item
        item_to_send = unsent_items.min_by { |i| i[:pub_date] }

        message = @builder.build(item_to_send)

        @messengers.each do |messenger|
            next if messenger.seen?(item_to_send[:guid])

            begin
                messenger.send(item_to_send, message)
                messenger.mark_seen(item_to_send[:guid])
                puts "Sent to #{messenger.name}."
            rescue StandardError => e
                warn "Failed to send to #{messenger.name}: #{e.message}"
            end
        end
    end
end
