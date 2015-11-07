class Home < ActiveRecord::Base
  has_many :fields
    
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
    fields.each {|field| @data[field.name] = field.value}
  end
end
