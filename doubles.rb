require 'open-uri'
require 'nokogiri'
require_relative 'programs'

tables = { 'http://www.surgu.ru/sveden/education' =>
               ['eduAccred', 'eduPriem', 'eduPerevod', 'eduNir'],
           'http://www.surgu.ru/sveden/grants' => ['graduateJob'],
           'http://www.surgu.ru/sveden/vacant' => ['vacant'] }

def get_html(url)
  begin
    Nokogiri::HTML(open(url))
  rescue
    puts "Error with url: #{url}"
  end
end

def find_tags_by_itemprop(tags, itemprop)
  tags.select do |tag|
    tag.attribute('itemprop').value == itemprop if tag.attribute('itemprop')
  end
end

def get_trs_by_itemprop(all_trs, attributes)
  current_trs = []
  if attributes.respond_to?('each')
    attributes.each { |attrib| current_trs += find_tags_by_itemprop(all_trs, attrib) }
  else
    current_trs = find_tags_by_itemprop(all_trs, attributes)
  end
  current_trs
end

def create_hash_element(td_elements, name)

end

def get_info(all_trs, attributes)
  current_trs = get_trs_by_itemprop(all_trs, attributes)
  tags_with_codes = []
  current_trs.each do |tr|
    tds = tr.css('td')
    program_info = {}
    program_info[:code] = find_tags_by_itemprop(tds, 'eduCode').content
    program_info[:name] = find_tags_by_itemprop(tds, 'eduName').content
    program_info[:level] = find_tags_by_itemprop(tds, 'eduLevel').content
    case attributes
    when 'vacant'
      program_info[:course] = find_tags_by_itemprop(tds, 'eduCourse').content
    when 'eduAccred'
    when 'eduPriem'
    when 'eduPerevod'
      program_info[:form] = find_tags_by_itemprop(tds, 'eduForm').content
    end
    form = find_tags_by_itemprop(tds, 'eduForm')
    tags_with_codes << { code: code, name: name, level: level, form: form }
  end
  # tags_with_codes.map { |tag| tag.content }.uniq
end

all_codes = {}
tables.each do |url, main_attributes|
  all_trs = get_html(url).css('tr').select { |tr| tr.attribute('itemprop') }
  p all_trs
  # main_attributes.each do |attributes|
  #   all_codes[attributes] = get_info(all_trs, attributes)
  # end
end