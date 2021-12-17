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
require 'ruby-progressbar'
require 'etc'

$BASE_URI     = 'https://vimm.net'
$DOWNLOAD_URI = 'https://download2.vimm.net'

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

def print_consoles_table
  puts Terminal::Table.new rows: [
    [0, 'Nintendo'],
    [1, 'Genesis'],
    [2, 'SuperNintendo'],
    [3, 'Saturn'],
    [4, 'PlayStation'],
    [5, 'Nintendo'],
    [6, 'Dreamcast'],
    [7, 'PlayStation2'],
    [8, 'Xbox'],
    [9, 'GameCube'],
    [10, 'PlayStation3'],
    [11, 'Wii'],
    [12, 'WiiWare']
  ], headings: %w[№ Console-Name]
end

# @param  [String] query
#
# @return [TrueClass, FalseClass]
#
def create_games_table(query)
  uri = $BASE_URI + query

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

  uri_str = "#{$DOWNLOAD_URI}/download/?mediaId=#{document.at('input[name="mediaId"]')['value'].to_str}"

  uri = URI(uri_str)

  puts "Downloading #{$games[game_num]['title']} to #{$SAVING_DIRECTORY} directory"

  progressbar = ProgressBar.create(format: '%a %b>%i %p%% %t',
                                   progress_mark: '=',
                                   remainder_mark: '-')

  Net::HTTP.start(uri.host, uri.port,
                  use_ssl: uri.scheme == 'https') do |http|
    request = Net::HTTP::Get.new(uri)
    request['Accept'] = 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8'
    request['Host'] = 'download2.vimm.net'
    request['Referer'] = 'https://vimm.net/'
    request['User-Agent'] = 'Mozilla/5.0'
    request['Accept-Language'] = 'en-US,en;q=0.5'
    request['Sec-Fetch-Dest'] = 'document'
    request['Sec-Fetch-Mode'] = 'navigate'
    request['Sec-Fetch-Site'] = 'same-site'
    request['Sec-Fetch-User'] = '?1'
    request['Upgrade-Insecure-Requests'] = '1'

    http.request request do |response|
      file_size = response['content-length'].to_i
      amount_downloaded = 0

      open($SAVING_DIRECTORY+$games[game_num]['title'], 'wb') do |io|
        response.read_body do |chunk|
          io.write chunk
          amount_downloaded += chunk.size
          progressbar.progress = (amount_downloaded.to_f / file_size) * 100
        end
      end
    end
  end

  system 'clear'
  puts 'Done.'

  false
end

########################################################################################################################
system 'clear'
is_dir = false
consoles = %w[
  NES
  Genesis
  SNES
  Saturn
  PS1
  N64
  Dreamcast
  PS2
  Xbox
  GameCube
  PS3
  Wii
  WiiWare
]

loop do
  if is_dir
    puts 'Change the saving directory? [y/N]'
    print '-> '
    input = gets.chomp.to_str

    is_dir = false if %w[y Y].include?(input)
  end

  unless is_dir
    $SAVING_DIRECTORY = "/home/#{Etc.getlogin}/Downloads"
    puts "Write the saving directory (Enter for default #{$SAVING_DIRECTORY})"
    print '-> '
    input = gets.chomp.to_str

    $SAVING_DIRECTORY = input unless [''].include?(input)

    unless File.directory?($SAVING_DIRECTORY)
      system 'clear'
      puts "\e[41mNo such directory #{$SAVING_DIRECTORY}\e[0m"
      next
    end

    system 'clear'
    is_dir = true
  end

  $games = []

  print_consoles_table
  puts 'Choose your console'
  print '-> '
  num = gets.chomp.to_i
  system 'clear'

  unless num >= 0 && num <= 12
    puts "\e[41mWrong number...\e[0m"
    next
  end

  console = consoles[num]

  loop do
    puts "Enter the title of the #{console} game for searching (q for back to console changing)"
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
    puts "\e[42mDone!\e[0m"
  end
end
