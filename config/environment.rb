# Load the rails application
require File.expand_path('../application', __FILE__)

# load all required files
puts "-"*80
Dir.glob("#{::Rails.root.to_s}/lib/**/*.rb") do |lib|
  puts "[E] loading library '#{lib.gsub(::Rails.root.to_s,'')}'"
  require lib
end
puts "-"*80

# Initialize the rails application
Kouzelnik::Application.initialize!
