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
    
    nodes = doc.css('div.REPORT_STDBOX')

    nodes.each do |node|
      home = Home.new
      info = node.text
      home.listing_id = pull_info(info, /AMML#:(\d+?)Area/)
      if Home.where(listing_id: home.listing_id).count > 0
        # If we already have the home, skip it for now.
        # TODO: figure out what should be updated for the old home.
        next
      end
      home.price = pull_info(info, /List Price:(.*?)Addr:/)
      home.address = pull_info(info, /Addr:(.*?)Unit#/)[0...-3] # Chop off Map symbol
      home.add_detail('lot_range', pull_info(info, /Lot Size:(.*?)# Acres/))
      home.add_detail('lot_dimensions', pull_info(info, /Lot Dimensions:(.*?)Wtfrnt/))
      home.add_detail('lot_description', pull_info(info, /Lot Desc:(.*?)Body Water/))
      home.add_detail('square_footage', pull_info(info, /Total SQFT:(.*?)Addl/))
      home.add_detail('description', pull_info(info, /Public:(.*?)APPROXIMATE/))
      home.add_detail('bedrooms', pull_info(info, /#Bdrms:(.*?)#Bath/))
      home.add_detail('bathrooms', pull_info(info, /#Bath:(.*?)#Lvl:/))
      home.add_detail('year_built', pull_info(info, /Year Built:(\d+?)\s*\/\s*REMOD/))
      home.add_detail('parking', pull_info(info, /Parking:(.*?)Exterior/))
      home.add_detail('garage', pull_info(info, /#Gar:(.*?)Bsmt/))
      
      image_count = info.scan(/photocaptions/).count - 1
      home.add_detail('image_count', image_count)
      home.save_images(session_data, image_count)
      
      home.save_zillow_url
      home.save!
    end
    
  end
  
  def self.pull_info(info, regex)
    info =~ regex ? $1.strip : ''
  end
  
  
  def save_images(session_data, image_count) 
    s3 = Aws::S3::Resource.new(region:'us-west-2')
    agent = Mechanize.new
    cookie = Mechanize::Cookie.new :domain => '.rmlsweb.com', 
                                   :name => 'RMLSWEBSESSIONID', 
                                   :value => session_data, 
                                   :path => '/', 
                                   :expires => (Date.today + 1).to_s
    agent.cookie_jar << cookie    
    
    image_count.to_i.times do |i|
      index = i + 1
      original_url = "http://www.rmlsweb.com/V4/subsys/LLPM/photo.aspx?mlsn=#{listing_id}&idx=#{index}"
      source_file = 'tmp/photo'
      agent.get(original_url).save!(source_file) # overwrite previous photos
      path = "house/#{listing_id}/#{index}"
      object = s3.bucket('evanpon.applications').object(path)
      object.upload_file(source_file, {acl: 'public-read'})
      puts "uploaded #{path}."
    end    
  end
  

  def image_url(index=1)
    "https://s3-us-west-2.amazonaws.com/evanpon.applications/house/#{listing_id}/#{index}"
  end

  def add_detail(name, value)
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
    details.new(name: 'zillow_url', value: zillow_url)
  end
  
  def google_map_url
    api_key = 'AIzaSyA7NyiO-jk7tGZkrTEPp9RCHT6R6vo4Z6U'
    address_param = CGI.escape("#{address}, Portland OR")
    "https://www.google.com/maps/embed/v1/place?key=#{api_key}&q=#{address_param}&zoom=14"
  end

  def lot_info
    if lot_dimensions.length > 0
      lot = lot_dimensions
    else
      lot = lot_range
    end
    "#{lot} (#{lot_description})"
  end
  
end
