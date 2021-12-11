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
require 'down/net_http'

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

  uri = URI($BASE_URI + $games[game_num].to_str)

  # I really hate you vimm and your browser is acting funny." 400 page.
  headers = {
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
    'Upgrade-Insecure-Requests' => '1'
  }

  # Super Mario Bros url for tests
  # uri = URI('https://download2.vimm.net/download/?mediaId=818')

  # TODO: Add progress bar
  game_archive = Down::NetHttp.download(uri, headers: headers).open.gets

  # TODO: Add custom download directories
  File.open($games[game_num]['title'], 'w') do |f|
    f.write(game_archive)
  end

  false
end

system 'clear'

loop do
  $games = []
  puts 'Enter the title of the game'
  print '-> '
  input = gets.chomp.to_str

  if create_games_table input
    puts 'Enter the game\'s num (q for back to search)'
    print '-> '
    input = gets.chomp.to_str

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
