module ErrorsLog
  def self.add_message(e, base_url, code, profile, params)
    name = @common_info[code][:name]
    level_name = @common_info[code][:level]
    File.open('log0.html', 'a') do |file|
      file.write "<div style='margin-bottom: 20px;'><p>Ошибка с ОПОП в #{code} #{name} #{level_name}</p>"
      file.write "<p>профиль: #{profile}</p>" if profile != '1'
      file.write "<p>#{params[:fgos]}&nbsp;&nbsp;&nbsp;&nbsp;" if params[:fgos]
      str = '<p>'
      str += "#{params[:fgos]}&nbsp;&nbsp;&nbsp;&nbsp;" if params[:fgos]
      str += "форма: #{params[:form]}&nbsp;&nbsp;&nbsp;&nbsp;" if params[:form]
      str += "год: #{params[:year]}&nbsp;&nbsp;&nbsp;&nbsp;" if params[:year]
      str += '</p>'
      file.write str
      file.write "<a href='#{base_url}'>Адрес каталога с ОПОП, где произошла ошибка</a></p>" if base_url
      file.write e.message
      file.write "</div>"
    end
  end

  def self.initial
    File.open('log0.html', 'w') do |file|
      file.write '<html>'
      file.write '<head><style>p { margin: 0; }</style></head><body>'
    end
  end
end