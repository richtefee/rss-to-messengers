#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../lib/message_builder'

# Fixed test item
test_item = {
    guid: "https://example.com/article/123",
    title: "This is the breaking news TITLE",
    summary: "This is a summary with text.",
    link: "https://example.com/article/123",
    feed_name: "Example Feed"
}

# Initialize builder with header and footer
builder = MessageBuilder.new(
    header: "________THIS IS A HEADER________",
    footer: "________THIS IS A FOOTER________"
)

# Build and print message
puts "Generated message:\n\n"
puts builder.build(test_item)
