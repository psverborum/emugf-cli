require 'uri'
require 'net/http'
require 'nokogiri'
require 'terminal-table'

$base_uri = 'https://vimm.net/vault/?p=list&system=PS1&q='

def print_table(array)
  header = %w[Title Players Year Serial Rating]
  array.delete(header)
  table = Terminal::Table.new rows: array, headings: header
  puts table
end

def print_games_table(game_name)
  base_uri = $base_uri
  base_uri += game_name

  html     = Net::HTTP.get(URI(base_uri))
  document = Nokogiri::HTML(html)

  games_array_table = []

  document.at('table').search('tr').each do |row|
    games_array_table << row.search('th, td').map { |cell| cell.text.strip }
  end

  print_table(games_array_table)
end

print_games_table(gets)
