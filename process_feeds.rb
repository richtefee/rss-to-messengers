#!/usr/bin/env ruby
# frozen_string_literal: true

require 'bundler/setup'

require_relative 'lib/processor'
require_relative 'lib/messengers'

# ===============================
# CONFIGURATION
# ===============================
CONFIG = {
  feeds_file: 'feeds.json',                  # path to your feeds
  header: nil,                 # can be nil
  footer: nil,                # can be nil
  include_fields: [:title, :summary, :link],# fields to include in message
  messengers: [:telegram, :whatsapp]        # which messengers to use: :whatsapp, :telegram
  }

# Initialize messenger objects
messengers = []
messengers << WhatsAppMessenger.new if CONFIG[:messengers].include?(:whatsapp)
messengers << TelegramMessenger.new if CONFIG[:messengers].include?(:telegram)

# Run processor
Processor.new(
  feeds_file: CONFIG[:feeds_file],
  messengers: messengers,
  message_config: CONFIG
).run
