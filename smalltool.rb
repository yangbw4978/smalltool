require 'net/http'
require 'iconv'
require 'uri'
require 'open-uri'
require 'tk'
require 'win32ole'

class Fetcher_and_Analylize
  attr_accessor :all_commodity_sortby_price
  def initialize
    @url = ""
    @html_file = ""
    @array_all_commodity = ""
  end
  
  def get_url(key_word)
    return "http://search.dangdang.com/?key=#{key_word}"
  end

  def fetch(url)
    html_content = open(url).read
    #抓取网页成功
    return html_content         
  end
  
  def analylize(html_file)
    hash_commodity = {}
    array_all_commodity = []
    conv = Iconv.new('utf-8', 'gbk')
    html_file_utf8 = conv.iconv(html_file)
    data = html_file_utf8.split(/<!--\s{1,20}<div class=\"inner\">-->/)
    data.each do |commodity|
      hash_commodity["commodity_name"] = commodity[/<a title=\"[\s\S]*\"\s{1,6}class=\"pic\"/].to_s.gsub("<a title=\"", "").gsub(/\"\s{1,6}class=\"pic\"/, "").lstrip
      hash_commodity["author_name"] = commodity[/name=\'itemlist-author\' title=\'[\s\S]{1,100}\'>/].to_s.gsub("name=\'itemlist-author\' title=\'", "").gsub("\'>", "").lstrip
      hash_commodity["publish_name"] = commodity[/name=\'P_cbs\' title=\'[\s\S]{1,50}\'>/].to_s.gsub("name=\'P_cbs\' title=\'", "").gsub("\'>", "").lstrip
      hash_commodity["price"] = commodity[/class=\"search_pre_price\">\&yen\;\d{1,4}\.\d{1,3}/].to_s.gsub("class=\"search_pre_price\">\&yen\;", "").lstrip.to_f
      hash_commodity["commodity_link"] = commodity[/class=\"pic\" name=\"itemlist-picture\" href=\"[\s\S]*\"\s*target=\"_blank\" ><img data/].to_s.gsub("class=\"pic\" name=\"itemlist-picture\" href=\"", "").gsub(/\"\s*target=\"_blank\" ><img data/, "").lstrip
      array_all_commodity << hash_commodity
      hash_commodity = {}
    end
    
    array_all_commodity.each do |element|
        array_all_commodity.delete(element) if element["commodity_name"] == ""
    end
    return array_all_commodity
  end
  
  def sort_by_price(all_commodity_sortby_price)
    all_commodity_sortby_price.each_with_index do |el,i|  
      j = i - 1  
        while j >= 0  
          break if all_commodity_sortby_price[j]["price"] <= el["price"]  
          all_commodity_sortby_price[j + 1] = all_commodity_sortby_price[j]  
          j -= 1  
        end  
      all_commodity_sortby_price[j + 1] = el  
    end
    return all_commodity_sortby_price
  end
  
  def get_commodity_info(key_word)
    @url = self.get_url(key_word)
    @html_file = self.fetch(@url)
    @array_all_commodity = self.analylize(@html_file)
    @all_commodity_sortby_price = self.sort_by_price(@array_all_commodity)
  end
  
end

class User_UI
  attr_accessor :get_data
  def initialize
    @get_data = Fetcher_and_Analylize.new
    @list_data = []
    root = TkRoot.new { title "当当网图书信息查询器"; minsize(450,400) }  
    TkLabel.new(root) do
      text '请输入书名:'
      pack { padx 10; pady 15; side 'left'}  
      place('x'=>60, 'y'=>50)  
    end
    
    @search_name = TkEntry.new(root) do
      text 'user'
      pack('padx'=>10, 'pady'=>10)
      place('height' => 25,'width'  => 150,'x'=>130,'y'=>50)
    end
    
    serch_button_callback = proc{start_search_update_list}
    TkButton.new(root) do 
      text '开始查找'
      command serch_button_callback 
      pack('padx'=>10, 'pady'=>10)
      place('height' => 25,'width'  => 55,'x'=>300,'y'=>50)
    end
    
    link_to_web_callback = proc{link_to_web}
    TkButton.new(root) do 
      text '打开商铺'
      command link_to_web_callback 
      pack('padx'=>10, 'pady'=>10)
      place('height' => 25,'width'  => 55,'x'=>370,'y'=>50)
    end
    
    @list = TkListbox.new(root) do 
      selectmode 'single'
      place('height' => 240,'width'  => 320,'x'=>40,'y'=>100)
    end
    
    scroll_y = TkScrollbar.new(root) do
      orient 'vertical'
      place('height' => 240, 'x' => 360, 'y'=>100)
    end
    
    @list.yscrollcommand(proc { |*args|
        scroll_y.set(*args)
      })
    
    scroll_y.command(proc { |*args|
        @list.yview(*args)
      }) 

    scroll_x = TkScrollbar.new(root) do
      orient 'horizontal'
      place('width' => 320, 'x' => 40, 'y'=>340)
    end
    
    @list.xscrollcommand(proc { |*args|
        scroll_x.set(*args)
      })
    
    scroll_x.command(proc { |*args|
        @list.xview(*args)
      }) 
    
    Tk.mainloop
  end
  
  def start_search_update_list
    user_input = @search_name.value
    @get_data.get_commodity_info(user_input)
    self.update_list(@get_data.all_commodity_sortby_price)
  end
  
  def update_list(raw_data)
    unless @list_data == 0
      @list.delete(0, @list_data.size)
    end
    @list_data = raw_data
    @list_data.each_with_index do |item, index|
      str_tmp = "《" + item["commodity_name"] + "》" + "  " + item["author_name"] + "  " + item["publish_name"] + "  " + item["price"].to_s
      @list.insert(index, str_tmp)
    end
  end
  
  def link_to_web 
    ie = WIN32OLE.new('InternetExplorer.Application')    
    ie.visible = true  
    
    seldata = @list.curselection
    @list_data
    ie.navigate(@list_data[seldata[0]]["commodity_link"])
    
  end
  
end

a = User_UI.new
