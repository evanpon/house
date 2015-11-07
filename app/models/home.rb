require 'open-uri'

class Home < ActiveRecord::Base
  has_many :details
    
  def method_missing(method, *args, &block)
    value = @data[method.to_s]
    if value.nil?
      puts "no such"
      super(method, args, block)
    else
      value
    end
  end
  
  def data
    if @data.nil?
      reload_data
    end
    @data
  end
  
  def reload_data
    @data = {}
    details(true).each {|detail| @data[detail.name] = detail.value}
  end
  
  def self.parse_from_mls(url)
    doc = Nokogiri::HTML(open(url)) do |config|
      config.nonet
    end
    home = Home.new
    top_node = doc.css('table.V2_REPORT_PHOTOTABLE')
    
    home.price = top_node.xpath('//tr/td[2]/table[5]/tr/td[6]').text.strip    
    home.listing_id = top_node.xpath('//tr/td[2]/table[5]/tr/td[2]').text.strip
    home.address = top_node.xpath('//tr/td[2]/table[6]/tr/td[2]/text()').text.strip
    
    home.add_detail('//tr/td[2]/table[10]/tr[1]/td[2]', top_node, 'elementary_school')
    home.add_detail('//tr/td[2]/table[7]/tr/td[2]', top_node, 'city')
    home.add_detail('//tr/td[2]/table[10]/tr[2]/td[2]', top_node, 'high_school')

    home.save! 
    
    save_zillow_url   
  end
  
  def add_detail(xpath, node, name) 
    value = node.xpath(xpath).text.strip
    details.new(name: name, value: value)
  end
 
  
  def save_zillow_url
    uri = URI('http://www.zillow.com/search/RealEstateSearch.htm')
    params = {citystatezip: "#{address}, portland OR"}
    uri.query = URI.encode_www_form(params)
    response = Net::HTTP.get_response(uri)
    if response.code == '301'
      zillow_url = "http://www.zillow.com#{response.header['location']}"
    else
      zillow_url = "http://www.zillow.com/search/RealEstateSearch.htm?citystatezip=4414 SE 16th Ave, Portland OR"
    end
    details.create(name: 'zillow_url', value: zillow_url)
  end
  
end
