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

$BASE_URI     = 'https://vimm.net'
$DOWNLOAD_URI = 'download2.vimm.net'

# @param [String] games
#
def print_games_table(games)
  header = games[0]
  games.delete games[0]

  game_count = games.length

  game_count.times do |game_num|
    games[game_num] = [game_num] + games[game_num]
  end

  puts Terminal::Table.new rows: games, headings: (['№'] + header)
end

# @param  [String] query
#
# @return [TrueClass, FalseClass]
#
def create_games_table(query)
  uri  = $BASE_URI + query

  html     = Net::HTTP.get(URI(uri))
  document = Nokogiri::HTML html

  games_array_table = []

  # TODO: (or not todo) I don't know maybe i should create a pagination for this
  #
  # In any case, the page does not display all games by the search query.
  # I don't know how many exactly but I decided to take 10 from the very top.
  # I'm not sure if someone will try to find the game by name
  # but in the end they will get lost in 10 menu items. I'll think about it.... Maybe
  limit = 12

  table = document.at 'table'

  return false if table.nil?

  table.search('tr').each do |row|
    game = (row.search('th, td').map { |cell| cell.text.strip })
    games_array_table << game

    if limit < 12
      link = row.at('a')['href']
      $games << {
        'link' => link,
        'title' => game[0]
      }
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

  referer_uri = $BASE_URI + $games[game_num]['link'].to_str

  html     = Net::HTTP.get(URI(referer_uri))
  document = Nokogiri::HTML html

  download_route = "/download/?mediaId=#{document.at('input[name="mediaId"]')['value'].to_str}"

  # I really hate you vimm and your browser is acting funny." 400 page.
  # headers = {
  #     'Accept-Encoding' => 'gzip, deflate, br',
  #     'Connection' => 'keep-alive',
  #     'Accept' => 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8',
  #     'Host' => 'download2.vimm.net',
  #     'Referer' => 'https://vimm.net/vault/6116',
  #     'User-Agent' => 'Mozilla/5.0',
  #     'Accept-Language' => 'en-US,en;q=0.5',
  #     'Sec-Fetch-Dest' => 'document',
  #     'Sec-Fetch-Mode' => 'navigate',
  #     'Sec-Fetch-Site' => 'same-site',
  #     'Sec-Fetch-User' => '?1',
  #     'Upgrade-Insecure-Requests' => '1'
  # }

    # Super Mario Bros url for tests
    # uri = URI('https://download2.vimm.net/download/?mediaId=818')

    # TODO: Fix segmented loading
  Net::HTTP.start($DOWNLOAD_URI) do |http|
    f = open($games[game_num]['title'], 'wb')
    begin
      http.request_get(download_route,
                       'Accept-Encoding' => 'gzip, deflate, br',
                       'Connection' => 'keep-alive',
                       'Accept' => 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8',
                       'Host' => 'download2.vimm.net',
                       'Referer' => 'https://vimm.net/vault/6116',
                       'User-Agent' => 'Mozilla/5.0',
                       'Accept-Language' => 'en-US,en;q=0.5',
                       'Sec-Fetch-Dest' => 'document',
                       'Sec-Fetch-Mode' => 'navigate',
                       'Sec-Fetch-Site' => 'same-site',
                       'Sec-Fetch-User' => '?1',
                       'Upgrade-Insecure-Requests' => '1') do |resp|
        resp.read_body do |segment|
          f.write(segment)
        end
      end
  ensure
    f.close
    end
  end

  puts 'Done.'

  false
end

############################################################
system 'clear'
# TODO: Add consoles choice in the menu, i guess...
#
# TODO: So actually i should upgrade menu, i dont like it!
loop do
  $games = []
  puts 'Choose your console'
  print '-> '
  console = gets.chomp.to_str
  system 'clear'

  loop do
    puts "Enter the title of the #{console} game (q for back to console changing)"
    print '-> '
    search_query = gets.chomp.to_str
    system 'clear'

    break if search_query == 'q'

    query = "/vault/?p=list&system=#{console}&q=#{search_query}"

    if create_games_table query
      puts 'Enter the game\'s num (q for back to search)'
      print '-> '
      input = gets.chomp.to_str

      if input == 'q'
        system 'clear'
        next
      end

      if download_game input.chomp.to_i
        system 'clear'
        puts "\e[41mSaik! Dat was WRONG NUMBA!\e[0m"
        next
      end
    else
      system 'clear'
      puts "\e[41mNothing found... Try something else\e[0m"
      next
    end

    system 'clear'
    puts "\e[42m#{'Done!'}\e[0m"
  end
end
