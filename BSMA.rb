require 'open-uri'
require 'nokogiri'
require_relative 'methods'

@main_url = 'http://publish.surgu.ru/bsm/'
@result = {}

def func(program_tag)
  program_relative_path = href(program_tag)
  program_code = program_relative_path.delete('/')
  # return unless program_code.include? '.04.'
  # return if program_code != '05.04.06'
  @result[program_code.to_s] = {}
  return if %w(current last).include? program_code
  puts "load #{program_code} #{@common_info[program_code][:name]} #{@common_info[program_code][:level]}"
  url = @main_url + program_relative_path + '1/'

  # вытаскиваем ссылки на профили
  profiles_link_tags = get_links_list url
  profiles_link_tags.each do |profile_tag|
    profile_relative_path = href(profile_tag)
    profile_name = decode(profile_tag).delete('/')
    # next if profile_name != 'Адаптированная образовательная программа "Адаптивное физическое воспитание"'
    @result[program_code.to_s][profile_name.to_s] = {}

    # получаем полный адрес на профиль
    profile_url = url + profile_relative_path

    # вытаскиваем ссылки на ФГОСы
    fgoses_link_tags = get_links_list profile_url
    fgoses_link_tags.each do |fgos|
      fgos_name = decode(fgos).delete('/')

      # получаем полный адрес каталога с ФГОСом
      fgos_url = profile_url + href(fgos)

      uri = URI.escape('3 УЧЕБНЫЕ ПЛАНЫ/')
      up_url = fgos_url+ uri

      # получаем полный список учебных планов по текущему ФГОСу
      up_link_tags = get_links_list up_url
      next unless up_link_tags
      # puts "!!!!!!! #{program_code} #{profile_name} #{fgos_name}" unless up_link_tags

      up_link_tags.each do |edu_plan|
        up_file_name = decode(edu_plan)
        @forms.keys.each do |form|
          if up_file_name.index(form)
            @result[program_code.to_s][profile_name.to_s][form] ||= {}
            %w(2016 2017 2018 2019 2020 2021).each do |year|
              if up_file_name.index(year)
                @result[program_code.to_s][profile_name.to_s][form][year] = {}

                current_plan_url = up_url + href(edu_plan)
                @result[program_code.to_s][profile_name.to_s][form][year][:edu_plan_link] = current_plan_url

                set_values(@result[program_code.to_s][profile_name.to_s][form][year],
                           fgos_url,
                           program_code,
                           profile_name,
                           { fgos: fgos_name,
                             form: form,
                             year: year })
              end
            end
          end
        end
      end
    end
  end
  # p @result
end

puts count = @common_info.select { |k, v| [@levels[1], @levels[2], @levels[3]].include? v[:level] }.count
initial_log_file
programs_link_tags = get_links_list @main_url
threads = []
programs_link_tags.each do |program_tag|
  threads << Thread.new(program_tag) do |program_tag|
    func program_tag
  end
end
threads.each {|thr| thr.join }
generate_table
