# messengers.rb
require 'json'
require 'net/http'
require 'uri'

class Messenger
    attr_reader :name, :seen_file

    def initialize(name, seen_file)
        @name = name
        @seen_file = seen_file
        load_seen
    end

    def load_seen
        @seen = File.exist?(@seen_file) ? JSON.parse(File.read(@seen_file)) : []
    end

    def save_seen
        File.write(@seen_file, JSON.pretty_generate(@seen))
    end

    def seen?(guid)
        @seen.include?(guid)
    end

    def mark_seen(guid)
        @seen << guid
        save_seen
    end
end


# -------------------------
# WhatsApp
# -------------------------
class WhatsAppMessenger < Messenger
    ENDPOINT = URI('https://gate.whapi.cloud/messages/text')

    def initialize
        super("whatsapp", "seen/whatsapp.json")
    end

    def send(item, message)
        http = Net::HTTP.new(ENDPOINT.host, ENDPOINT.port)
        http.use_ssl = true

        req = Net::HTTP::Post.new(ENDPOINT)
        req['Authorization'] = "Bearer #{ENV['WHATSAPP_API_TOKEN']}"
        req['Content-Type'] = 'application/json'

        req.body = JSON.generate({
                                  to: ENV['WHATSAPP_CHANNEL'],
                                  body: message
                                 })

        resp = http.request(req)
        raise "WhatsApp error #{resp.code}" unless resp.code.start_with?('2')

        true
    end
end


# -------------------------
# Telegram: Notice also formatting transformation
# -------------------------
class TelegramMessenger < Messenger

    # HTML only requires escaping for three specific characters: <, >, and &.
    # This simplifies the escape logic greatly compared to MarkdownV2.
    HTML_ESCAPE_REGEX = /[&<>]/

    def initialize
        super("telegram", "seen/telegram.json")
    end

    # Applies essential HTML escaping to the text content, protecting it from being
    # mistaken for an HTML tag. This is applied to all *non-tag* content.
    def escape_html_content(text)
        return text.to_s.gsub(HTML_ESCAPE_REGEX, {
                                                  '&' => '&amp;',
                                                  '<' => '&lt;',
                                                  '>' => '&gt;'
                                                 }) unless text.nil?
    end

    # Translates the simple intermediate format (*bold*) to Telegram HTML (<b>bold</b>).
    def translate_to_telegram(message)
        # 1. Replace the simple bold format (*text*) with HTML tags (<b>text</b>).
        # We use a capture group to replace *TEXT* with <b>TEXT</b>.
        message = message.gsub(/\*([^\*]+)\*/, '<b>\1</b>')

        # 2. To ensure safety, we must escape the content *outside* of the new <b> tags.
        # This is complex, so the safest approach is to escape all content first,
        # then replace the tags back.

        # Let's perform a similar placeholder hack as before for safety and simplicity,
        # but targeting the HTML tags.

        # HACK: Replace HTML tags with a placeholder to shield them from the escape function.
        message = message.gsub('<b>', '---BOLD-START---').gsub('</b>', '---BOLD-END---')

        # 3. Apply general HTML escaping to the rest of the message.
        message = escape_html_content(message)

        # 4. Swap the placeholder back to the HTML tags.
        message = message.gsub('---BOLD-START---', '<b>').gsub('---BOLD-END---', '</b>')

        return message
    end

    def send(item, message)
        # Prepare the message for Telegram
        telegram_message = translate_to_telegram(message)

        uri = URI("https://api.telegram.org/bot#{ENV['TELEGRAM_BOT_TOKEN']}/sendMessage")

        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true

        req = Net::HTTP::Post.new(uri)
        req['Content-Type'] = 'application/json'

        req.body = JSON.generate({
                                  chat_id: ENV['TELEGRAM_CHAT_ID'],
                                  text: telegram_message,
                                  parse_mode: "HTML" # CRITICAL CHANGE: Use HTML mode
                                 })

        resp = http.request(req)

        # --- Robust Error Handling ---

        # 1. Check HTTP Status Code
        unless resp.code.start_with?('2')
            raise "Telegram HTTP Error: Code #{resp.code}. Body: #{resp.body}"
        end

        # 2. Check Telegram API Operational Status ('ok' field)
        begin
            response_data = JSON.parse(resp.body)
        rescue JSON::ParserError
            raise "Telegram API Error: Invalid JSON response. Body: #{resp.body}"
        end

        if response_data['ok'] == false
            error_description = response_data['description'] || 'No description provided.'
            raise "Telegram API Operation Failed: #{error_description} (Code: #{response_data['error_code']})"
        end

        true
    end
end
