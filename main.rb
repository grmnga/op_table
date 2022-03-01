require 'open-uri'
require 'nokogiri'
require_relative 'programs'

@forms = {'_ОФО' => 'очная', '_ЗФО'=> 'заочная'}
@main_url = 'http://publish.surgu.ru/bsm/'
@result = {}

def get_links_list(url)
  begin
    html = Nokogiri::HTML(open(url))
    links = html.css('pre a')
    links.shift
    links
  rescue
    puts "Не удалось открыть #{url}"
  end
end

def func(program_tag)
  program_relative_path = program_tag.attribute('href').value
  program_code = program_relative_path.delete('/')
  @result[program_code.to_s] = {}
  url = @main_url + program_relative_path + '1/'

  # получаем профили направления
  profiles_link_tags = get_links_list url
  profiles_link_tags.each do |profile_tag|
    profile_relative_path = profile_tag.attribute('href').value
    profile_name = URI.decode(profile_relative_path.delete('/'))
    @result[program_code.to_s][profile_name.to_s] = {}
    profile_url = url + profile_relative_path

    # смотрим внутри каждого ФГОС'а
    fgoses_link_tags = get_links_list profile_url
    fgoses_link_tags.each do |fgos|
      uri = URI.escape('3 УЧЕБНЫЕ ПЛАНЫ/')
      fgos_url = profile_url + fgos.attribute('href').value
      edu_plans_url = fgos_url+ uri
      edu_plans = get_links_list edu_plans_url
      edu_plans.each do |edu_plan|
        file_url = URI.decode(edu_plan.attribute('href').value)
        @forms.keys.each do |form|
          if file_url.index(form)
            # p @result
            @result[program_code.to_s][profile_name.to_s][form] ||= {}
            %w(2015 2016 2017 2018 2019 2020).each do |year|
              if file_url.index(year)
                @result[program_code.to_s][profile_name.to_s][form][year] = {}

                current_plan_url = edu_plans_url + edu_plan.attribute('href').value
                @result[program_code.to_s][profile_name.to_s][form][year][:edu_plan_link] = current_plan_url

                uri = URI.escape('1 ОБЩАЯ ХАРАКТЕРИСТИКА/')
                opop_url = fgos_url + uri
                @result[program_code.to_s][profile_name.to_s][form][year][:opop] = opop_url

                uri = uri = URI.escape('2 КАЛЕНДАРНЫЙ ГРАФИК/')
                edu_shed_folder_url = fgos_url + uri
                edu_shed_links = get_links_list edu_shed_folder_url
                edu_shed_url = edu_shed_folder_url + edu_shed_links.last.attribute('href').value
                @result[program_code.to_s][profile_name.to_s][form][year][:edu_shed] = edu_shed_url

                uri = URI.escape('4 РАБОЧИЕ ПРОГРАММЫ ДИСЦИПЛИН/')
                rpd_folders_url = fgos_url + uri
                rpd_links = get_links_list rpd_folders_url
                rpd_links.each do |rpd_folder|
                  folder_name = URI.decode(rpd_folder.attribute('href').value)
                  if folder_name.index(form)
                    if folder_name.index(year)
                      rpd_url = rpd_folders_url + rpd_folder.attribute('href').value
                      @result[program_code.to_s][profile_name.to_s][form][year][:rpd] = rpd_url
                    end
                  end
                end
              end
            end
          end
        end
      end
    end
  end
  # p @result
end

def generate_table
  File.open('result.html', 'w') do |file|
    file.write "<table><tbody>"\
                "<tr>"\
                "<td>Код</td>"\
                "<td>Наименование специальности, направления подготовки</td>"\
                "<td>Уровень образования</td>"\
                "<td>Реализуемые формы обучения</td>"\
                "<td>Ссылка на описание образовательной программы с приложением ее копии (в том числе РПД)</td>"\
                "<td>Ссылка на учебный план</td>"\
                "<td>Ссылка на аннотации к рабочим программам дисциплин (по каждой дисциплине в составе образовательной программы)</td>"\
                "<td>Ссылка на календарный учебный график</td>"\
                "<td>Ссылка на методические и иные документы, разработанные образовательной организацией для обеспечения образовательного процесса</td>"\
                "<td>Ссылка на рабочие программы практик, предусмотренных соответствующей образовательной программой</td>"\
                "<td>Использование при реализации образовательных программ электронного обучения и дистанционных образовательных технолгий</td>"\
                "</tr>"\
                "<tr>"\
                "<td>1</td><td>2</td><td>3</td><td>4</td><td>5</td><td>6</td><td>7</td><td>8</td><td>9</td><td>10</td><td>11</td>"\
                "</tr>"
    # p @result
    # $stdout = File.open('output.txt', 'w')
    @common_info.each_key do |code|
      # p "#{code}: #{@common_info[code][:level]} #{@common_info[code][:name]}"
      if @result[code]
        @result[code].each do |profile_name, forms|
          forms.sort.reverse.to_h.each do |form_name, years|
            years.sort.reverse.to_h.each do |year, links|
              # p @common_info[code][:name]
              name = @common_info[code][:name] + "<br>(Профиль: #{profile_name})"
              level = @common_info[code][:level]
              form = @forms[form_name]
              opop = "<a href=#{links[:opop]} itemprop='opMain'>ОПОП ВО</a><br><a href=#{links[:rpd]} itemprop='opMain'>РПД</a>"
              edu_plan = "<a href=#{links[:edu_plan_link]} itemprop='educationPlan'>Учебный план #{year}</a>"
              rpd = "<a href=#{links[:rpd]} itemprop='educationAnnotation'>РПД ОС</a>"
              edu_shed = "<a href=#{links[:edu_shed]} itemprop='educationShedule'>Календарный учебный график 2020-2021</a>"
              rpp = "<a href=#{links[:rpd]} itemprop='eduPr'>РПП</a>"

              file.write "<tr itemprop='eduOp'>"\
                       "<td itemprop='eduCode'>#{code}</td>"\
                       "<td itemprop='eduName'>#{name}</td>"\
                       "<td itemprop='eduLevel'>#{level}</td>"\
                       "<td itemprop='eduForm'>#{form}</td>"\
                       "<td>#{opop}</td>"\
                       "<td>#{edu_plan}</td>"\
                       "<td>#{rpd}</td>"\
                       "<td>#{edu_shed}</td>"\
                       "<td></td>"\
                       "<td>#{rpp}</td>"\
                       "<td itemprop='eduEl'>нет</td>"\
                       "</tr>"
            end
          end
        end
      end
    end
  end
end

programs_link_tags = get_links_list @main_url
programs_link_tags.each do |program_tag|
  func program_tag
end
generate_table
