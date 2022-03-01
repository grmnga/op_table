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
  return if program_code != '49.03.02'
  @result[program_code.to_s] = {}
  return if %w(current last).include? program_code
  puts "load #{program_code} #{@common_info[program_code][:name]} #{@common_info[program_code][:level]}"
  url = @main_url + program_relative_path + '1/'

  # вытаскиваем ссылки на профили
  profiles_link_tags = get_links_list url
  profiles_link_tags.each do |profile_tag|
    profile_relative_path = profile_tag.attribute('href').value
    profile_name = URI.decode(profile_relative_path.delete('/'))
    next if profile_name != 'Адаптированная образовательная программа "Адаптивное физическое воспитание"'
    puts profile_name
    @result[program_code.to_s][profile_name.to_s] = {}

    # получаем полный адрес на профиль
    profile_url = url + profile_relative_path

    # вытаскиваем ссылки на ФГОСы
    fgoses_link_tags = get_links_list profile_url
    fgoses_link_tags.each do |fgos|
      fgos_name = URI.decode(fgos.attribute('href').value.delete('/'))

      # получаем полный адрес каталога с ФГОСом
      fgos_url = profile_url + fgos.attribute('href').value

      uri = URI.escape('3 УЧЕБНЫЕ ПЛАНЫ/')
      up_url = fgos_url+ uri

      # получаем полный список учебных планов по текущему ФГОСу
      up_link_tags = get_links_list up_url
      begin
        up_link_tags.each do |edu_plan|
          up_file_name = URI.decode(edu_plan.attribute('href').value)
          @forms.keys.each do |form|
            if up_file_name.index(form)
              @result[program_code.to_s][profile_name.to_s][form] ||= {}
              %w(2015 2016 2017 2018 2019 2020).each do |year|
                if up_file_name.index(year)
                  @result[program_code.to_s][profile_name.to_s][form][year] = {}

                  current_plan_url = up_url + edu_plan.attribute('href').value
                  @result[program_code.to_s][profile_name.to_s][form][year][:edu_plan_link] = current_plan_url
                  begin
                    uri = URI.escape('1 ОБЩАЯ ХАРАКТЕРИСТИКА/')
                    opop_url = fgos_url + uri
                    @result[program_code.to_s][profile_name.to_s][form][year][:opop] = opop_url
                  rescue
                    puts "Ошибка с ОПОП в #{profile_name} форма: #{form} год: #{year}"
                  end

                  begin
                    uri = URI.escape('2 КАЛЕНДАРНЫЙ ГРАФИК/')
                    edu_shed_folder_url = fgos_url + uri
                    edu_shed_links = get_links_list edu_shed_folder_url
                    edu_shed_url = edu_shed_folder_url + edu_shed_links.last.attribute('href').value
                    @result[program_code.to_s][profile_name.to_s][form][year][:edu_shed] = edu_shed_url
                  rescue
                    puts "Ошибка с КУГ в #{profile_name} форма: #{form} год: #{year}"
                    puts "Адрес каталога: #{edu_shed_folder_url}"
                  end

                  begin
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
                  rescue
                    puts "Ошибка с РПД в #{profile_name} форма: #{form} год: #{year}"
                  end

                  begin
                    uri = URI.escape('6 ОТЧЁТЫ О ПРАКТИКАХ/')
                    rpp_folders_url = fgos_url + uri
                    rpp_links = get_links_list rpp_folders_url
                    rpp_links.each do |rpp_folder|
                      folder_name = URI.decode(rpp_folder.attribute('href').value)
                      if folder_name.index(form)
                        if folder_name.index(year)
                          rpp_url = rpp_folders_url + rpp_folder.attribute('href').value
                          @result[program_code.to_s][profile_name.to_s][form][year][:rpp] = rpp_url
                        end
                      end
                    end
                  rescue
                    File.open('log.html', 'a') do |file|
                      file.write "<div style='margin-bottom: 20px;'><p>Ошибка с РПП в #{program_code} #{@common_info[program_code][:name]} #{@common_info[program_code][:level]}</p>"
                      file.write "<p>профиль: #{profile_name}</p>"
                      file.write "<p>#{fgos_name}&nbsp;&nbsp;&nbsp;&nbsp;форма: #{form}&nbsp;&nbsp;&nbsp;&nbsp;год: #{year}&nbsp;&nbsp;&nbsp;&nbsp;"
                      file.write "<a href='#{@result[program_code.to_s][profile_name.to_s][form][year][:rpd]}'>Адрес каталога с РПД</a></p></div>"
                    end
                    puts "Ошибка с РПП в #{program_code} #{profile_name} #{fgos_name} форма: #{form} год: #{year}"
                    puts "Адрес каталога с РПД: #{@result[program_code.to_s][profile_name.to_s][form][year][:rpd]}"
                  end
                end
              end
            end
          end
        end
      rescue
        puts "Error with edu_plan in #{profile_name}"
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
                "<td>Ссылки на рабочие программы (по каждой дисциплине в составе образовательной программы)</td>"\
                "<td>Ссылка на календарный учебный график</td>"\
                "<td>Ссылка на методические и иные документы, разработанные образовательной организацией для обеспечения образовательного процесса</td>"\
                "<td>Ссылка на рабочие программы практик, предусмотренных соответствующей образовательной программой</td>"\
                "<td>Использование при реализации образовательных программ электронного обучения и дистанционных образовательных технолгий</td>"\
                "</tr>"\
                "<tr>"\
                "<td>1</td><td>2</td><td>3</td><td>4</td><td>5</td><td>6</td><td>7</td><td>8</td><td>9</td><td>10</td><td>11</td><td>12</td>"\
                "</tr>"
    # p @result
    # $stdout = File.open('output.txt', 'w')
    @common_info.each_key do |code|
      # p "#{code}: #{@common_info[code][:level]} #{@common_info[code][:name]}"
      if @result[code]
        puts "generate #{code} #{@common_info[code][:name]} #{@common_info[code][:level]}"
        @result[code].each do |profile_name, forms|
          forms.sort.reverse.to_h.each do |form_name, years|
            years.sort.reverse.to_h.each do |year, links|
              # p @common_info[code][:name]
              name = @common_info[code][:name] + "<br>(Профиль: #{profile_name})"
              level = @common_info[code][:level]
              form = @forms[form_name]
              opop = "<a href=#{links[:opop]} itemprop='opMain'>ОПОП ВО</a><br>"
              edu_plan = "<a href=#{links[:edu_plan_link]} itemprop='educationPlan'>Учебный план #{year}</a>"
              rpd = "<a href=#{links[:rpd]} itemprop='educationAnnotation'>РПД ОС</a>"
              edu_shed = "<a href=#{links[:edu_shed]} itemprop='educationShedule'>Календарный учебный график 2020-2021</a>"
              metod_link = "<a href='http://lib.surgu.ru/fulltext/Umm/'>Методические материалы</a>"
              rpp = "<a href='#{links[:rpp]}' itemprop='eduPr'>РПП</a>"

              file.write "<tr itemprop='eduAdOp'>"\
                       "<td itemprop='eduCode'>#{code}</td>"\
                       "<td itemprop='eduName'>#{name}</td>"\
                       "<td itemprop='eduLevel'>#{level}</td>"\
                       "<td itemprop='eduForm'>#{form}</td>"\
                       "<td itemprop='opMain'>#{opop}</td>"\
                       "<td itemprop='educationPlan'>#{edu_plan}</td>"\
                       "<td itemprop='educationAnnotation'>#{rpd}</td>"\
                       "<td itemprop='educationRpd'>#{rpd}</td>"\
                       "<td itemprop='educationShedule'>#{edu_shed}</td>"\
                       "<td itemprop='methodology'>#{metod_link}</td>"\
                       "<td itemprop='eduPr'>#{rpp}</td>"\
                       "<td itemprop='eduEl'>нет</td>"\
                       "</tr>"
            end
          end
        end
      end
    end
  end
end

# @common_info.each { |k, v| p v[:level] }
# puts count = @common_info.select { |k, v| [@levels[1], @levels[2], @levels[3]].include? v[:level] }.count
File.open('log.html', 'w'){ |file| file.write '<html>' }
programs_link_tags = get_links_list @main_url
programs_link_tags.each do |program_tag|
  func program_tag
end
generate_table


# puts "Найдено кодов: #{@result[code]}, В численности: #{count}"