# message_builder.rb
# frozen_string_literal: true


# WhatsApp Compatible Intermediate Format --> Transformed in messengers.rb for others.
class MessageBuilder
    def initialize(header: nil, footer: nil)
        @header = header
        @footer = footer
    end

    # Builds a message using WhatsApp's minimal formatting (*Title*)
    def build(item)
        parts = []
        parts << @header if @header

        # WhatsApp compatible bolding (single asterisks)
        parts << "*#{item[:title]}*" if item[:title]
        parts << item[:summary] if item[:summary]
        parts << item[:link] if item[:link] # Link remains separate, unformatted
        parts << @footer if @footer

        parts.compact.join("\n\n")
    end
end
