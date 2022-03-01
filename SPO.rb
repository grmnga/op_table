require 'open-uri'
require 'nokogiri'
require_relative 'methods'

@main_url = 'http://publish.surgu.ru/spo/'
@result = {}

def func(program_tag)
  program_relative_path = program_tag.attribute('href').value
  program_code = program_relative_path.delete('/')
  @result[program_code.to_s] = {}
  return if %w(current last).include? program_code
  puts "load #{program_code} #{@common_info[program_code][:name]} #{@common_info[program_code][:level]}"

  profile_name = '1'
  @result[program_code.to_s][profile_name.to_s] = {}
  profile_url = @main_url + program_relative_path + '1/'

  uri = URI.escape('1.3_УЧЕБНЫЕ ПЛАНЫ/')
  edu_plans_url = profile_url + uri
  edu_plans = get_links_list edu_plans_url
  edu_plans.each do |edu_plan|
    file_url = decode(edu_plan)
    @forms.keys.each do |form|
      if file_url.index(form) && file_url.index('.pdf')
        @result[program_code.to_s][profile_name.to_s][form] ||= {}
        %w(2015 2016 2017 2018 2019 2020 2021).each do |year|
          if file_url.index(year)
            @result[program_code.to_s][profile_name.to_s][form][year] = {}

            current_plan_url = edu_plans_url + href(edu_plan)
            @result[program_code.to_s][profile_name.to_s][form][year][:edu_plan_link] = current_plan_url

            set_values(@result[program_code.to_s][profile_name.to_s][form][year],
                       profile_url,
                       program_code,
                       profile_name,
                       { form: form,
                         year: year })
          end
        end
      end
    end
  end
end

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
