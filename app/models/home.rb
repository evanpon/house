require 'open-uri'

class Home < ActiveRecord::Base
  has_many :details
  has_one :scorecard
  
  accepts_nested_attributes_for :scorecard
  DETAILS = [:lot_range, :lot_dimensions, :lot_description, :square_footage, :description,
             :bedrooms, :bathrooms, :year_built, :parking, :garage, :list_date, :property_tax,
             :image_count, :zillow_url, :portland_map_url, :walk_score, :transit_score,
             :bike_score]
  
  def method_missing(method, *args, &block)
    if DETAILS.include?(method)
      data[method.to_s]
    else
      super(method, args, block)
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
  
  def self.find_list_date(url)
    doc = Nokogiri::HTML(open(url)) do |config|
      config.nonet
    end
    nodes = doc.css('div.REPORT_STDBOX')

    nodes.each_with_index do |node, index|
      info = node.text
      listing_id = pull_info(info, /MML#:(\d+?)Area/)
      home = Home.where(listing_id: listing_id).first
      if home
        begin
          puts home.list_date
        rescue Exception  
          home.add_detail('list_date', pull_info(info, /List Date(.*?)COMPARABLE/))
          home.save!
        end
      end
    end
  end
    
  def listed
    begin
      home.list_date
    rescue Exception
      ""
    end
  end
  
  def self.parse_from_mls(url, session_data)
    doc = Nokogiri::HTML(open(url)) do |config|
      config.nonet
    end
    
    nodes = doc.css('div.REPORT_STDBOX')

    if nodes.size > 10
      Home.update_all("active = 0")
    end

    nodes.each do |node|
      info = node.text
      listing_id = pull_info(info, /MML#:(\d+?)Area/)
      next if listing_id.blank?
      
      home = Home.find_or_initialize_by(listing_id: listing_id)
      home.active = true

      # Always update price, since that changes.
      home.price = pull_info(info, /List Price:(.*?)Addr:/)
      
      # Only update these fields the first time, they don't change. 
      if home.new_record?
        home.address = pull_info(info, /Addr:(.*?)Unit#/)[0...-3] # Chop off Map symbol
        home.add_detail('lot_range', pull_info(info, /Lot Size:(.*?)# Acres/))
        home.add_detail('lot_dimensions', pull_info(info, /Lot Dimensions:(.*?)Wtfrnt/))
        home.add_detail('lot_description', pull_info(info, /Lot Desc:(.*?)Body Water/))
        home.add_detail('square_footage', pull_info(info, /Total SQFT:(.*?)Addl/))
        home.add_detail('description', pull_info(info, /Public:(.*?)APPROXIMATE/))
        home.add_detail('bedrooms', pull_info(info, /#Bdrms:(.*?)#Bath/))
        home.add_detail('bathrooms', pull_info(info, /#Bath:(.*?)#Lvl:/))
        home.add_detail('year_built', pull_info(info, /Year Built:(\d+?)\s*\//))
        home.add_detail('parking', pull_info(info, /Parking:(.*?)Exterior/))
        home.add_detail('garage', pull_info(info, /#Gar:(.*?)Bsmt/))
        home.add_detail('list_date', pull_info(info, /List Date(.*?)COMPARABLE/))
        home.add_detail('property_tax', pull_info(info, /PTax\/Yr:(.*?)Rent/))

        image_count = info.scan(/photocaptions/).count - 1
        home.add_detail('image_count', image_count)
        home.save_images(session_data, image_count)

        home.save_zillow_url
        home.save_portland_map_url
        home.add_walk_scores

        home.scorecard = Scorecard.new
      end
      home.save!
    end
    
  end
  
  def self.add_year(url, session_data)
    doc = Nokogiri::HTML(open(url)) do |config|
      config.nonet
    end

    nodes = doc.css('div.REPORT_STDBOX')

    nodes.each do |node|
      info = node.text
      listing_id = pull_info(info, /MML#:(\d+?)Area/)
      next if listing_id.blank?

      home = Home.where(listing_id: listing_id).first
      home.active = true
      year = pull_info(info, /Year Built:(\d+?)\s*\//)
      puts "Home #{listing_id} was built in #{year}"
      detail = home.details.where(name: 'year_built').first
      if detail
        detail.value = year
        detail.save!
      end
      # home.add_detail(:year_built, year)
      # home.save!
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
    # "/#{listing_id}/#{index}"
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
  
  def calculate_value
    ((scorecard.calculate_score * 1000000) / price_as_float).round(1)
  end
  
  def price_as_float
    price.gsub(/[^\d\.]/, '').to_f
  end
  
  def add_walk_scores
    hyphenated_address = address.strip.gsub(/\s+/, '-').gsub(',', '')    
    url = "https://www.walkscore.com/score/#{hyphenated_address}-portland-or"
    
    doc = Nokogiri::HTML(open(url)) do |config|
      config.nonet
    end
    
    html = doc.css('div#address-header').first.inner_html

    %w(walk transit bike).each do |type|
      html =~ /pp.walk.sc\/badge\/#{type}\/score\/(\d+).png/
      details.new(name: "#{type}_score", value: $1)
      puts $1
    end
  end
  
  def save_portland_map_url
    encoded = URI.escape(address.strip)
    uri = URI("http://www.portlandmaps.com/parse_results.cfm?query=#{encoded}")
    response = Net::HTTP.get_response(uri)
    if response.header['location'] =~ /propertyid=(\w+)&/
      url = "https://www.portlandmaps.com/detail/property/#{$1}_did/"
    else
      url = "https://www.portlandmaps.com/#{response.header['location']}"
    end
    details.new(name: 'portland_map_url', value: url)
  end
  
  def score
    scorecard.calculate_score
  end
end
