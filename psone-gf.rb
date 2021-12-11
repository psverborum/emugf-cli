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

$base_uri = 'https://vimm.net/vault/?p=list&system=PS1&q='

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
  base_uri  = $base_uri
  base_uri += game_name

  html     = Net::HTTP.get(URI(base_uri))
  document = Nokogiri::HTML(html)

  games_array_table = []
  limit = 12

  table = document.at('table')

  return false if table.nil?

  table.search('tr').each do |row|
    games_array_table << (row.search('th, td').map { |cell| cell.text.strip })

    if limit < 12
      link = row.at('a')['href']
      @games << link
    end

    break if (limit -= 1).zero?
  end

  print_games_table games_array_table

  true
end

def download_game(game_num)
  uri = $base_uri + @games[game_num]
end

system 'clear'

loop do
  @games = []
  puts 'Enter the title of the game'
  print '-> '
  input = gets.chomp.to_str

  if create_games_table input
    # input = gets.chomp.to_str

  else
    system 'clear'
    puts "\e[41mNothing found... Try something else\e[0m"
  end
end
