#!/usr/bin/env ruby

require 'telegram/bot'

token = '671231490:AAFY-9018O4wViUxgKImZfJlpl9hfHyubvw'

quotes = [
  "That's what I love about these high school girls, man. I get older, they stay the same age.",
  "All right, all right, all right."
]

Telegram::Bot::Client.run(token) do |bot|
  bot.listen do |message|
    case message.text
    when /^no$/i
      bot.api.send_message(chat_id: message.chat.id, text: "It'd be a lot cooler if you did.")
    when /^yes$/i
      bot.api.send_message(chat_id: message.chat.id, text: "Alright, alright, alright.")
    end
  end
end
