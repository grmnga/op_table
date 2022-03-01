require 'open-uri'
require 'nokogiri'
require_relative 'programs'

tables = { 'http://www.surgu.ru/sveden/education' =>
                [['eduAccred', 'eduPOAccred'], 'eduPriem', 'eduPerevod', ['eduOp', 'eduAdOp'], 'eduNir'],
            'http://www.surgu.ru/sveden/grants' => ['graduateJob'],
            'http://www.surgu.ru/sveden/vacant' => ['vacant'] }

def get_html(url)
  begin
    Nokogiri::HTML(open(url))
  rescue
    puts "Error with url: #{url}"
  end
end

def get_tags_with_itemprop_from_url(tag_name, url)
  html = get_html(url)
  get_tags_with_itemprop(html, tag_name)
end

def get_tags_with_itemprop(tags, tag_name)
  tags.css(tag_name).select { |tag| tag.attribute('itemprop') }
end

def tag_has_current_itemprop?(tag, itemprop)
  tag.attribute('itemprop').value == itemprop
end

def find_tags_by_itemprop(tags, itemprop)
  tags.select do |tag|
    tag_has_current_itemprop?(tag, itemprop) if tag.attribute('itemprop')
  end
end

# def get_chislen_codes
#   rows = get_tags_with_itemprop_from_url('tr', 'http://www.surgu.ru/sveden/education') #get_html('http://www.surgu.ru/sveden/education').css('tr').select { |tr| tr.attribute('itemprop') }
#   chislen_rows = find_tags_by_itemprop(rows, 'eduChislen') #rows.select { |row| row.attribute('itemprop').value == 'eduChislen' }
#   chislen_codes = []
#   chislen_rows.each do |tr|
#     tds = get_tags_with_itemprop(tr, 'td') #tr.css('td').select { |td| td.attribute('itemprop') }
#     tds.each do |td|
#       chislen_codes << td.content if tag_has_current_itemprop?(td, 'eduCode') #td.attribute('itemprop').value == 'eduCode'
#     end
#   end
#   chislen_codes.uniq
# end

# def get_trs_by_itemprop(all_trs, attributes)
#   current_trs = []
#   if attributes.respond_to?('each')
#     attributes.each { |attrib| current_trs += find_tags_by_itemprop(all_trs, attrib) }
#   else
#     current_trs = find_tags_by_itemprop(all_trs, attributes)
#   end
#   current_trs
# end

def get_codes(current_trs, attributes)
  # current_trs = get_trs_by_itemprop(all_trs, attributes)
  tags_with_codes = []
  current_trs.each do |tr|
    tds = get_tags_with_itemprop(tr, 'td')
    # tds = tr.css('td').select { |td| td.attribute('itemprop') }
    tags_with_codes += find_tags_by_itemprop(tds, 'eduCode')
  end
  tags_with_codes.map { |tag| tag.content }.uniq
end

def get_tags_with_current_itemprop(tags, itemprop)
  all_tags = get_tags_with_itemprop(tags, 'td')
  find_tags_by_itemprop(all_tds, itemprop)
end

def get_codes_from_table(url, table_attribute)
  all_trs = get_tags_with_itemprop_from_url('tr', url)
  current_trs = find_tags_by_itemprop(all_trs, table_attribute)
  get_codes(current_trs, table_attribute)

  # all_tds = []
  # current_trs.each do |tr|
  #   all_tds += get_tags_with_itemprop(tr, 'td')
  # end
  # tds_with_code = find_tags_by_itemprop(all_tds, 'eduCode')
  # tds_with_code.map { |tag| tag.content }.uniq
end

chislen_codes = get_codes_from_table('http://www.surgu.ru/sveden/education', 'eduChislen')

all_codes = {}
tables.each do |url, main_attributes|
  main_attributes.each do |attribute|
    all_codes[attribute] = get_codes_from_table(url, attribute)
  end
  # all_trs = get_tags_with_itemprop_from_url('tr', url) #get_html(url).css('tr').select { |tr| tr.attribute('itemprop') }
  # main_attributes.each do |attributes|
  #   all_codes[attributes] = get_codes(all_trs, attributes)
  # end
end

all_codes.each do |itemprop, codes|
  puts
  puts "Itemprop: #{itemprop}, total codes: #{codes.count}, difference: #{chislen_codes.count - codes.count}"
  chislen_codes.each do |code|
    unless codes.include? code
      puts "#{@common_info[code][:level]} #{code} #{@common_info[code][:name]}"
    end
  end
end
