require_relative 'programs'

def get_links_list(url)
  html = Nokogiri::HTML(open(url))
  links = html.css('pre a')
  links.shift
  links
rescue
  puts "Не удалось открыть #{url}"
end

def decode(str)
  URI.decode(str.attribute('href').value)
end

def href(node)
  node.attribute('href').value
end

def get_level_by_code(code)
  @levels.index(@common_info[code][:level])
end

def name_include_year_and_form?(name, params)
  name.index(params[:form]) && name.index(params[:year])
end

def get_opop_links(links, level)
  text_level = level == 0? 'СПО' : 'ВО'
  # <a href=#{links[:rpd]}>РПД</a></p>"
  "<p style='margin-bottom: 5px'><a href=#{links[:opop]}>ОПОП #{text_level}</a></p><p style='margin-bottom: 5px'>"
end

def get_edu_plan_link(links, year)
  "<a href=#{links[:edu_plan_link]}>Учебный план #{year}</a>"
end

def get_rpd_link(links, level)
  text_level = level == 0? 'ФОС' : 'ОС'
  "<a href=#{links[:rpd]}>РПД #{text_level}</a>"
end

def get_edu_shed_link(links, year, level)
  year = '2021-2022' if (1...3).include? level
  "<a href=#{links[:edu_shed]}>Календарный учебный график #{year}</a>"
end

def get_rpp_auto_link(links)
  "<a href='#{links[:rpp]}'>РПП</a>"
end

def get_rpp_file_link(rpp_file_info)
  "<p style='margin-bottom: 5px'><a href=#{rpp_file_info[:url]}>#{rpp_file_info[:name]}</a></p>"
end

def get_rpp_links(links, level)
  case level
    when 0..3
      "<a href='#{links[:rpp]}'>РПП</a>"
    when 4..5
      links[:rpp].map { |rpp_info| get_rpp_file_link(rpp_info) }.join('') if links[:rpp]
  else
    ''
  end
end

def get_method_link(level)
  opt_link = case level
             when 0
               "<p style='margin-bottom: 5px'><a href='http://medcollege.surgu.ru/activity/education/-ep'>Образовательные программы</a></p>"
             when 1..3
               "<p style='margin-bottom: 5px'><a href='http://www.surgu.ru/studentu/vypusknye-kvalifikatsionnye-raboty/obschaya-informatsiya'>ВКР</a></p>"
             when 4
               "<p style='margin-bottom: 5px'><a href='http://www.surgu.ru/nauka/aspirantura/uchebnyy-protsess'>Учебный процесс</a></p>"
             when 5
               "<p style='margin-bottom: 5px'><a href='http://www.surgu.ru/instituty/meditsinskiy-institut/uchebnaya-deyatelnost/tsentr-ordinatury/ob-yavleniya'>Объявления</a></p>"
             end
  "<p style='margin-bottom: 5px'><a href='http://lib.surgu.ru/fulltext/Umm/'>Методические материалы</a></p>"\
  "#{opt_link}"\
  "<p style='margin-bottom: 5px'><a href='http://www.surgu.ru/studentu/obraztsy-dokumentov'>Образцы документов</a></p>"\
  "<p style='margin-bottom: 5px'><a href='http://www.surgu.ru/sotrudniku/dokumenty-sistemy-menedzhmenta-kachestva'>Документы системы менеджмента качества</a></p>"\
  "<p style='margin-bottom: 5px'><a href='http://lib.surgu.ru/index.php?view=s&sid=124'>Электронный каталог</a></p>"
end

def get_program_info_hash(code, form, year, links, profile_name = '')
  program_info = {}
  level = get_level_by_code(code)
  program_info[:code] = code
  program_info[:name] = if profile_name
    @common_info[code][:name] + "<br>(Профиль: #{profile_name})"
  else
    @common_info[code][:name]
  end
  program_info[:level] = @common_info[code][:level]
  program_info[:form] = @forms[form]
  program_info[:opop] = get_opop_links(links, level)
  program_info[:edu_plan] = get_edu_plan_link(links, year)
  program_info[:rpd] = get_rpd_link(links, level)
  program_info[:edu_shed] = get_edu_shed_link(links, year, level)
  program_info[:metod_link] = get_method_link(level)
  program_info[:rpp] = get_rpp_links(links, level)
  program_info
end

def create_table
  File.open('result.html', 'w') do |file|
    file.write "<style> table { border-collapse: collapse; } td { border: 1px solid; padding: 5px; } </style>"
    file.write "<table class='ten'><tbody>"\
                  "<tr>"\
                  "<td>Код</td>"\
                  "<td>Наименование специальности, направления подготовки</td>"\
                  "<td>Уровень образования</td>"\
                  "<td>Реализуемые формы обучения</td>"\
                  "<td>Ссылка на описание образовательной программы с приложением ее копии</td>"\
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
    end
end

def add_tr(params)
  File.open('result.html', 'a') do |file|
    file.write "<tr itemprop='eduOp'>"\
                         "<td itemprop='eduCode'>#{params[:code]}</td>"\
                         "<td itemprop='eduName'>#{params[:name]}</td>"\
                         "<td itemprop='eduLevel'>#{params[:level]}</td>"\
                         "<td itemprop='eduForm'>#{params[:form]}</td>"\
                         "<td itemprop='opMain'>#{params[:opop]}</td>"\
                         "<td itemprop='educationPlan'>#{params[:edu_plan]}</td>"\
                         "<td itemprop='educationAnnotation'>#{params[:rpd]}</td>"\
                         "<td itemprop='educationRpd'>#{params[:rpd]}</td>"\
                         "<td itemprop='educationShedule'>#{params[:edu_shed]}</td>"\
                         "<td itemprop='methodology'>#{params[:metod_link]}</td>"\
                         "<td itemprop='eduPr'>#{params[:rpp]}</td>"\
                         "<td itemprop='eduEl'>нет</td>"\
                         "</tr>"
  end
end

def generate_table
  puts 'Starting generate the table...'
  create_table
  @common_info.each_key do |code|
    if @result[code]
      @result[code].each do |profile_name, forms|
        profile_name = nil if profile_name == '1'
        forms.sort.reverse.to_h.each do |form_name, years|
          years.sort.reverse.to_h.each do |year, links|
            program_info = get_program_info_hash(code, form_name, year, links, profile_name)
            add_tr(program_info)
          end
        end
      end
    end
  end
  puts 'Done'
end

def opop_folder_name(level)
  case level
  when 0, 5
    URI.escape('1.1_ОБЩАЯ ХАРАКТЕРИСТИКА/')
  when 1..4
    URI.escape('1 ОБЩАЯ ХАРАКТЕРИСТИКА/')
  else
    raise "Ошибка в уровне образования. Ожидается в диапазоне 0..5. Получено: #{level}"
  end
end

def set_opop(base_url, code, profile, params)
  level = get_level_by_code(code)
  uri = opop_folder_name level
  opop_url = base_url + uri
  opops = get_links_list opop_url
  raise 'Каталог с ОПОП пустой' if opops.empty?
  case level
    when 0
      opop_url = opop_url + set_spo_opop(opops, params[:year], params[:form])
      opop_files = get_links_list opop_url
      raise 'Каталог ОПОП пуст' if opop_files.empty?
    when 4
      opop_url += set_asp_opop(opops, params[:year])
  end
rescue => e
  puts "Ошибка в ОПОП #{code} #{@common_info[code][:name]}\t#{@common_info[code][:level]}"
  add_error_in_log_file(e, opop_url, code, profile, params)
ensure
  return opop_url
end

def set_asp_opop(opops, year)
  opop_file = opops.select { |file| decode(file).index(year) }
  raise 'Не найден файл ОПОП' if opop_file.empty?
  raise 'Файлов ОПОП больше одного' if opop_file.size > 1
  href(opop_file.first)
end

def set_spo_opop(opops, year, form)
  opop_folder = opops.select { |folder| decode(folder).index(year) && decode(folder).index(form)  }
  raise 'Не найден каталог ОПОП' if opop_folder.empty?
  raise 'Каталогов ОПОП больше одного' if opop_folder.size > 1
  href(opop_folder.first)
end

def edu_shed_folder_name(level)
  case level
    when 0, 5
      URI.escape('1.2_КАЛЕНДАРНЫЙ ГРАФИК/')
    when 1..4
      URI.escape('2 КАЛЕНДАРНЫЙ ГРАФИК/')
    else
      raise "Ошибка в уровне образования. Ожидается в диапазоне 0..5. Получено: #{level}"
  end
end

def set_edu_shedule(base_url, code, profile, params)
  level = get_level_by_code(code)
  uri = edu_shed_folder_name(level)
  shedule_folder_url = base_url + uri
  shedule_files = get_links_list shedule_folder_url
  shedule_file = find_shedule(shedule_files, params, level)
  raise 'Не найден файл КУГ' if shedule_file.empty?
  raise 'Файлов КУГ больше одного' if shedule_file.size > 1
  shedule_folder_url + href(shedule_file.first)
rescue => e
  puts "Ошибка в КУГ #{code} #{@common_info[code][:name]}\t#{@common_info[code][:level]}"
  add_error_in_log_file(e, shedule_folder_url, code, profile, params)
end

def find_shedule(files, params, level)
  case level
    when 0, 4..5
      files.select do |link|
        file_name = decode(link)
        name_include_year_and_form?(file_name, params)
      end
  when 1..3
    xls = files.select { |link| decode(link).include?(params[:form]) && decode(link).include?('.xls') }.size
    pdf = files.select { |link| decode(link).include?(params[:form]) && decode(link).include?('.pdf') }.size
    if xls != 0 && pdf != 0
      files = files.select { |link| decode(link).include?(params[:form]) && decode(link).include?('.xls') }
    end
      files.select { |link| decode(link).index(params[:form]) }
  else
    raise "Ошибка в уровне образования. Ожидается в диапазоне 0..5. Получено: #{level}"
  end
end

def str_with_params(params)
  str = '<p>'
  str += "#{params[:fgos]}&nbsp;&nbsp;&nbsp;&nbsp;" if params[:fgos]
  str += "форма: #{params[:form]}&nbsp;&nbsp;&nbsp;&nbsp;" if params[:form]
  str += "год: #{params[:year]}" if params[:year]
  str += '</p>'
end

def add_error_in_log_file(e, base_url, code, profile, params)
  name = @common_info[code][:name]
  level_name = @common_info[code][:level]
  File.open('log0.html', 'a') do |file|
    file.write "<div style='margin-bottom: 20px;'><p>Ошибка в #{code} #{name} #{level_name}</p>"
    file.write "<p>профиль: #{profile}</p>" if profile != '1'
    file.write str_with_params(params)
    file.write e.message
    file.write "<p><a href='#{base_url}'>Адрес каталога, где произошла ошибка</a></p>" if base_url
    file.write "</div>"
  end
end

def initial_log_file
  File.open('log0.html', 'w') do |file|
    file.write '<html>'
    file.write '<head><style>p { margin: 0; }</style></head><body>'
  end
end

def rpd_folder_name(level)
  case level
  when 0, 5
    URI.escape('1.4_РАБОЧИЕ ПРОГРАММЫ ДИСЦИПЛИН/')
  when 1..4
    URI.escape('4 РАБОЧИЕ ПРОГРАММЫ ДИСЦИПЛИН/')
  else
    raise "Ошибка в уровне образования. Ожидается в диапазоне 0..5. Получено: #{level}"
  end
end

def rpp_folder_name(level)
  case level
    when 0
      URI.escape('../5/')
    when 1..3
      URI.escape('6 ОТЧЁТЫ О ПРАКТИКАХ/')
    else
      raise "Ошибка в уровне образования. Ожидается в диапазоне 0..5. Получено: #{level}"
  end
end

def set_rpd(base_url, code, profile, params)
  level = get_level_by_code(code)
  rpp = []
  rpd_url = ''
  uri = rpd_folder_name(level)
  rpd_folders_url = base_url + uri
  rpd_links = get_links_list rpd_folders_url
  rpd_links.each do |rpd_folder|
    folder_name = decode(rpd_folder)
    if name_include_year_and_form?(folder_name, params)
      rpd_url = rpd_folders_url + href(rpd_folder)
      rpp_links = get_links_list rpd_url
      raise 'Каталог с РПД пуст' if rpp_links.empty?
      rpp = set_aspord_rpp(rpd_url, code, profile, params) if (4..5).include? level
      break
    end
  end
  rpp = set_bsmspo_rpp(base_url, code, profile, params) if (0..3).include? level
  raise 'Не найдены РПД' if rpd_url.empty?
rescue => e
  puts "Ошибка в РПД #{code} #{@common_info[code][:name]}\t#{@common_info[code][:level]}"
  add_error_in_log_file(e, rpd_url, code, profile, params)
ensure
  return [rpd_url, rpp]
end

def set_bsmspo_rpp(base_url, code, profile, params)
  level = get_level_by_code(code)
  rpp = []
  uri = rpp_folder_name level
  rpp_folders_url = base_url + uri
  rpp_links = get_links_list rpp_folders_url
  raise 'Не найдены РПП' unless rpp_links
  rpp_links.each do |rpp_folder|
    folder_name = decode(rpp_folder)
    if name_include_year_and_form?(folder_name, params)
      rpp = rpp_folders_url + href(rpp_folder)
      rpp_files = get_links_list rpp
      raise 'Каталог РПП пуст' if rpp_files.empty?
      break
    end
  end
  raise 'Не найдены РПП' if rpp.empty?
rescue => e
  puts "Ошибка в РПП #{code} #{@common_info[code][:name]}\t#{@common_info[code][:level]}"
  add_error_in_log_file(e, rpp_folders_url, code, profile, params)
ensure
  return rpp
end

def set_aspord_rpp(base_url, code, profile, params)
  rpp = []
  # rpp_url = ''
  rpp_links = get_links_list base_url
  rpp_links.each do |rpd_file|
    rpd_file_name = decode(rpd_file)
    if is_rpp? rpd_file_name
      next if rpd_file_name.index('Дополнения')
      rpp_url = base_url + href(rpd_file)
      rpp << { name: rpd_file_name[3...-4], url: rpp_url }
      unless rpd_file_name.downcase.index('практика')
        e = Exception.new("Не найдено ключевое слово 'практика' в #{rpd_file_name}")
        add_error_in_log_file(e, base_url, code, nil, params)
      end
    end
  end
  raise 'Не найдены РПП' if rpp.empty?
  raise "РПП больше двух (#{rpp.size} шт)" if rpp.size > 2
rescue => e
  puts "Ошибка в РПП. #{code} #{@common_info[code][:name]}\t#{@common_info[code][:level]}"
  add_error_in_log_file(e, base_url, code, profile, params)
ensure
  return rpp
end

def is_rpp?(file_name)
  file_name.downcase.index('практика') ||
    file_name.index('НИП') ||
    file_name.index('ПП') ||
    file_name.index(' пр.') ||
    file_name.index('.пр.')
end

def set_values(result, base_url, code, profile, params)
  result[:opop] = set_opop(base_url, code, profile, params)
  result[:edu_shed] = set_edu_shedule(base_url, code, profile, params)
  result[:rpd], result[:rpp] = set_rpd(base_url, code, profile, params)
end