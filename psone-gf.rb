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

def print_games_table(games)
  header = %w[Title Players Year Serial Rating]
  games.delete(header)

  game_count = games.length

  game_count.times do |game_num|
    games[game_num] = [game_num] + games[game_num]
  end

  table = Terminal::Table.new rows: games, headings: (['№'] + header)

  puts table
end

def create_games_table(game_name)
  base_uri  = $base_uri
  base_uri += game_name

  html     = Net::HTTP.get(URI(base_uri))
  document = Nokogiri::HTML(html)

  games_array_table = []

  document.at('table').search('tr').each do |row|
    games_array_table << (row.search('th, td').map { |cell| cell.text.strip })
  end

  print_games_table(games_array_table)
end

create_games_table(gets.chomp.to_str)
