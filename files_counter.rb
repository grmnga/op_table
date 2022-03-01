
# puts File.join("01.03.02/1", "**", "3 УЧЕБНЫЕ ПЛАНЫ", "*.pdf")
# puts Dir.glob(File.join("01.03.02/1", "**", "3 УЧЕБНЫЕ ПЛАНЫ", "*.pdf"))

def get_profiles(code)
  Dir.entries("#{code}/1").reject { |folder_name| ['.', '..'].include? folder_name  }
end

def get_children(parent)
  Dir.chdir(parent)
  # puts Dir.pwd
  Dir.entries(".").reject { |folder_name| ['.', '..'].include? folder_name  }
end

def get_edu_plans
  Dir.glob(File.join("**", "3 УЧЕБНЫЕ ПЛАНЫ", "*.pdf"))
end

# root = "Y:/"  # БСМ
# root = "X:/"    # Аспирантура

# Dir.chdir(root)
# File.open('I:/ruby_projects/op_table/ups.txt', 'w') { |f| f.write '' }
# puts Dir.pwd
program_folders = Dir.entries("/").select { |folder_name| folder_name =~ /^[0-9]{2}[.]{1}[0-9]{2}[.]{1}[0-9]{2}$/ }

def get_program_folders
  Dir.entries("/").select { |folder_name| folder_name =~ /^[0-9]{2}[.]{1}[0-9]{2}[.]{1}[0-9]{2}$/ }
end

def set_root(level)
  case level
  when 0 then "V:/"
  when 1..3 then "Y:/"
  when 4 then "X:/"
  when 5 then "W:/"
  else
    raise "Неизвестный уровень образования #{level}"
  end
end

def get_log_file_name(level)
  log_file_name = case level
              when 0 then 'spo'
              when 1..3 then 'bsm'
              when 4 then 'asp'
              when 5 then 'ord'
              else
                raise "Неизвестный уровень образования #{level}"
              end
  "I:/ruby_projects/op_table/ups_#{log_file_name}.txt"
end

def init_log(level)
  log_file_name = get_log_file_name(level)
  File.open(log_file_name, 'w') { |f| f.write '' }
end

def add_to_log(level, edu_plan, code, profile = '', fgos = '')
  log_file = get_log_file_name(level)
  File.open(log_file, 'a') do |file|
    file.write "код: #{code.encode("UTF-8")}\tпрофиль: #{profile.encode("UTF-8")}\t#{fgos.encode("UTF-8")}\t"
    file.write edu_plan.encode("UTF-8")
    file.write "\r"
  end
end



# БСМ
def bsm
  level = 1
  root = set_root(level)
  Dir.chdir(root)
  init_log(level)
  program_folders = get_program_folders
  program_folders.each do |program_code|
    # puts "code: #{program_code}"
    profiles = get_children("#{program_code}/1")
    profiles.each do |profile|
      # puts "profile: #{profile}"
      fgoses = get_children profile
      fgoses.each do |fgos|
        # puts "fgos: #{fgos}"
        # puts "hjkh".encode "Windows-1251"
        path = File.join(fgos, "3 УЧЕБНЫЕ ПЛАНЫ".encode("Windows-1251"))
        ups = get_children(path)
        ups.each do |up|
          # if up.encode("UTF-8") !=~ /^УП_[ОФО]{1}[_]{1}[0-9]{4}.pdf$/
          if up.encode("UTF-8").index('УП') && up.encode("UTF-8").downcase.index('.pdf')
          # unless up.encode("UTF-8").index('Thumbs.db')
            @count += 1
            print '.'
          else
            add_to_log(level, up, program_code)
          end
        end
        # puts ups
        Dir.chdir('..')
        Dir.chdir('..')
      end
      Dir.chdir('..')
    end
    Dir.chdir(root)
  end
end

# Аспирантура
def asp
  level = 4
  root = set_root(level)
  Dir.chdir(root)
  init_log(level)
  program_folders = get_program_folders
  program_folders.each do |program_code|
    profiles = get_children("#{program_code}/1")
    profiles.each do |profile|
      path = File.join(profile, "3 УЧЕБНЫЕ ПЛАНЫ".encode("Windows-1251"))
      # puts path
      ups = get_children(path)
      ups.each do |up|
          if up.encode("UTF-8").index('УП') && up.encode("UTF-8").downcase.index('.pdf')
          # unless up.encode("UTF-8").index('Thumbs.db')
            @count += 1
            print '.'
          else
            add_to_log(level, up, program_code)
          end
      end
      Dir.chdir('..')
      Dir.chdir('..')
    end
    Dir.chdir(root)
  end
end

# Ординатура
def ord
  level = 5
  root = set_root(level)
  Dir.chdir(root)
  init_log(level)
  program_folders = get_program_folders
  program_folders.each do |program_code|
    path = File.join(program_code, "1/1.3_УЧЕБНЫЕ ПЛАНЫ".encode("Windows-1251"))
    ups = get_children(path)
    ups.each do |up|
      if up.encode("UTF-8").index('УП') && up.encode("UTF-8").downcase.index('.pdf')
        @count += 1
        print '.'
      else
        add_to_log(level, up, program_code)
      end
    end
    Dir.chdir(root)
  end
end

# СПО
def spo
  level= 0
  root = set_root(level)
  Dir.chdir(root)
  init_log(level)
  program_folders = get_program_folders
  program_folders.each do |program_code|
    path = File.join(program_code, "1/1.3_УЧЕБНЫЕ ПЛАНЫ".encode("Windows-1251"))
    ups = get_children(path)
    ups.each do |up|
      if up.encode("UTF-8").index('УП') && up.encode("UTF-8").downcase.index('.pdf')
        @count += 1
        print '.'
      else
        add_to_log(level, up, program_code)
      end
    end
    Dir.chdir(root)
  end
end

def start(level)
  print "start"
  @count = 0
  case level
  when 0 then spo
  when 1..3 then bsm
  when 4 then asp
  when 5 then ord
  else
    raise 'Что начать?'
  end
end

# start 1
#
# puts
# puts "Всего УП найдено: #{@count}"


%w(0 1 4 5).each do |i|
  start i.to_i
  puts
  puts "Всего УП найдено: #{@count}"
end

# start 4
# puts
# puts "Всего УП найдено: #{@count}"