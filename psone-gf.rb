#!/usr/bin/env ruby
#
# Created by VERBORUM
#
# Github:   github.com/GarrryJ
# Telegram: @verborum
#
# frozen_string_literal: true

require 'uri'
require 'net/http'
require 'nokogiri'
require 'terminal-table'

$BASE_URI = 'https://vimm.net'
$SEARCH_QUERY = '/vault/?p=list&system=PS1&q='

# @param [String] games
#
def print_games_table(games)
  header = %w[Title Players Year Serial Rating]
  games.delete header

  game_count = games.length

  game_count.times do |game_num|
    games[game_num] = [game_num] + games[game_num]
  end

  puts Terminal::Table.new rows: games, headings: (['№'] + header)
end

# @param  [String] game_name
#
# @return [TrueClass, FalseClass]
#
def create_games_table(game_name)
  uri  = $BASE_URI + $SEARCH_QUERY
  uri += game_name

  html     = Net::HTTP.get(URI(uri))
  document = Nokogiri::HTML(html)

  games_array_table = []
  limit = 12

  table = document.at('table')

  return false if table.nil?

  table.search('tr').each do |row|
    games_array_table << (row.search('th, td').map { |cell| cell.text.strip })

    if limit < 12
      link = row.at('a')['href']
      $games << link
    end

    break if (limit -= 1).zero?
  end

  print_games_table games_array_table

  true
end

# @param  [Integer] game_num
#
# @return [TrueClass, FalseClass]
#
def download_game(game_num)
  return true unless $games.length.times.include?(game_num)

  # uri = URI($BASE_URI + $games[game_num].to_str)
  #
  uri = URI('https://download2.vimm.net/download/?mediaId=4944')

  req = Net::HTTP::Get.new(uri)

  # I really hate you vimm and your browser is acting funny." 400 page.
  req['Accept-Encoding']           = 'gzip, deflate, br'
  req['Connection']                = 'keep-alive'
  req['Accept']                    = 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8'
  req['Host']                      = 'download2.vimm.net'
  req['Referer']                   = $BASE_URI + $games[game_num].to_str
  req['User-Agent']                = 'Mozilla/5.0'
  req['Accept-Language']           = 'en-US,en;q=0.5'
  req['Sec-Fetch-Dest']            = 'document'
  req['Sec-Fetch-Mode']            = 'navigate'
  req['Sec-Fetch-Site']            = 'same-site'
  req['Sec-Fetch-User']            = '?1'
  req['Upgrade-Insecure-Requests'] = 1

  game_archive = Net::HTTP.start(uri.hostname, uri.port) do |http|
    http.request(req)
  end

  File.open('out.zip', 'w') do |f|
    f.write(game_archive)
  end

  puts 'УРААААААААА YAAAAAAY'
  sleep 10

  false
end

system 'clear'

loop do
  $games = []
  puts 'Enter the title of the game'
  print '-> '
  input = 'tekken' #gets.chomp.to_str

  if create_games_table input
    puts 'Enter the game\'s num (q for back to search)'
    print '-> '
    input = '2'#gets.chomp.to_str

    if input == 'q'
      system 'clear'
      next
    end

    if download_game(input.chomp.to_i)
      system 'clear'
      puts "\e[41mSaik! Dat was WRONG NUMBA!\e[0m"
      next
    end
  else
    system 'clear'
    puts "\e[41mNothing found... Try something else\e[0m"
    next
  end
end
