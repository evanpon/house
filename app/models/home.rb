require 'open-uri'

class Home < ActiveRecord::Base
  has_many :details

  def method_missing(method, *args, &block)
    value = data[method.to_s]
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
  
  def self.parse_from_mls(url, session_data)
    doc = Nokogiri::HTML(open(url)) do |config|
      config.nonet
    end
    top_nodes = doc.css('table.V2_REPORT_PHOTOTABLE')
    top_nodes.each do |node|
      home = Home.new
      home.price = node.xpath('tr/td[2]/table[5]/tr/td[6]').text.strip  
        
      home.listing_id = node.xpath('tr/td[2]/table[5]/tr/td[2]').text.strip
      home.address = node.xpath('tr/td[2]/table[6]/tr/td[2]/text()').text.strip
    
      home.add_detail('tr/td[2]/table[10]/tr[1]/td[2]', node, 'elementary_school')
      home.add_detail('tr/td[2]/table[7]/tr/td[2]', node, 'city')
      home.add_detail('tr/td[2]/table[10]/tr[2]/td[2]', node, 'high_school')

      save_images(node, home, session_data)
      home.save! 

      home.save_zillow_url   
    end
  end
  
  def self.save_images(doc, home, session_data)
    # First get the image count
    count = 0
    node_set = doc.css("#linkShowPhotoNext_#{home.listing_id}")
    if node_set.length > 0
      node = node_set.first
      if node['onclick'] =~ /'next',(\d+)/
        count = $1
      end
    end
    home.details.new(name: 'image_count', value: count)
  
    # Now save all the images
    s3 = Aws::S3::Resource.new(region:'us-west-2')
    agent = Mechanize.new
    cookie = Mechanize::Cookie.new :domain => '.rmlsweb.com', 
                                   :name => 'RMLSWEBSESSIONID', 
                                   :value => session_data, 
                                   :path => '/', 
                                   :expires => (Date.today + 1).to_s
    agent.cookie_jar << cookie
    
    count.to_i.times do |i|
      index = i + 1
      original_url = "http://www.rmlsweb.com/V4/subsys/LLPM/photo.aspx?mlsn=#{home.listing_id}&idx=#{index}"
      source_file = 'tmp/photo'
      agent.get(original_url).save!(source_file) # overwrite previous photos
      path = "house/#{home.listing_id}/#{index}"
      object = s3.bucket('evanpon.applications').object(path)
      object.upload_file(source_file, {acl: 'public-read'})
      puts "uploaded #{path}."
    end
  end

  def image_url(index=1)
    "https://s3-us-west-2.amazonaws.com/evanpon.applications/house/#{listing_id}/#{index}"
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
  
  def google_map_url
    api_key = 'AIzaSyA7NyiO-jk7tGZkrTEPp9RCHT6R6vo4Z6U'
    address_param = CGI.escape("#{address}, Portland OR")
    "https://www.google.com/maps/embed/v1/place?key=#{api_key}&q=#{address_param}&zoom=14"
  end
end
