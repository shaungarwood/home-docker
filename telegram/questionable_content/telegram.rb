#!/usr/bin/env ruby

require 'telegram/bot'
require 'rss'

@token = '635844617:AAFDeUlXLUr1AYhwZwfUyqao2N8Cvf1eRC8' # L3-37
@chat_id = '641612303'

@feed_url = "https://www.questionablecontent.net/QCRSS.xml"

def push_telegram(item)
  message = format_message(item)

  puts "pushing via L3-37 bot: #{message}"
  Telegram::Bot::Client.run(@token) do |bot|
    bot.api.send_message(chat_id: @chat_id, text: message)
  end
end

def format_message(item)
  image_regex = /http:\/\/www\.questionablecontent\.net\/comics\/\d{4,5}\.png/
  image = item.description.scan(image_regex)

  message = ''
  if image.size == 1
    message << item.title + "\n"
    message << item.pubDate.to_s + "\n"
    message << item.link + "\n"
    message << image[0] + "\n"
  else
    message = "found #{image.size} image links in the questionable content feed's latest push"
  end

  return message
end

def get_latest
  feed = RSS::Parser.parse(@feed_url)
  return feed.items.first
end

def recently_published?(item)
  t = Time.now
  item.pubDate > t - (3*60*60) # in the last 3 hours
end

loop do
  latest = get_latest

  if recently_published?(latest)
    puts "found latest comic at #{Time.now}"
    push_telegram(latest)

    sleep (18*60*60) # 18 hours
  end

  printf '.'
  sleep (5*60) # 5 minutes
end
