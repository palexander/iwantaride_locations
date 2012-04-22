require 'rubygems'
require 'json'
require 'open-uri'
require 'hpricot'
require 'cgi'
require 'sinatra'
require 'parsedate'


get "/" do
  if params["guser_xml"].nil?
    # puts "Missing guser location"
    body "Please provide an address [EX: guser_xml=https%3A%2F%2Fwww.google.com%2Fcalendar%2Ffeeds%2F...]"
    status 400
    return
  end
    
  doc = open(params["guser_xml"]) { |f| Hpricot(f) }

  locations = []
  doc.search("/feed/entry/content").each do |el|
    time_match = el.inner_html.match(/When: (.*) to/)[1] rescue nil
    time = Time.mktime(*ParseDate.parsedate(time_match))
    next if time.nil?
    loc = el.inner_html.match(/Where: (.*)$/)[1] rescue nil
    next if loc.nil?
    geocode = JSON.parse(open("http://maps.googleapis.com/maps/api/geocode/json?address=#{CGI.escape(loc)}&sensor=false").read)
    target = geocode["results"][0]
    establishment = target["address_components"]["types"]["establishment"] rescue nil
    name = establishment.nil? ? loc : establishment
    longlat = geocode["results"][0]["geometry"]["location"] rescue nil
    next if longlat.nil?
    locations << { :address => target["formatted_address"], :name => name, :lat => longlat["lat"], :lng =>longlat["lng"], :datetime => time.strftime("%Y-%m-%d %H:%M:%S") }
  end

  content_type :json
  locations.to_json
end