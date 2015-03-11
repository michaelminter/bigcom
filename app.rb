require 'rubygems'
require 'sinatra'
require "sinatra/activerecord"
require './env' if File.exists?('env.rb')
require 'base62'
require 'chronic'
require 'nokogiri'
require 'open-uri'
require 'useragent'

enable :logging

configure do
  # set :database, {adapter: "postgresql", database: "bigcom_development"}
  set :views, File.dirname(__FILE__) + "/views" #todo fix this shit
end

helpers do
  def cycle
    %w{even odd}[@_cycle = ((@_cycle || -1) + 1) % 2]
  end

  CYCLE = %w{even odd}
  def cycle_fully_sick
    CYCLE[@_cycle = ((@_cycle || -1) + 1) % 2]
  end
end

class Redirect < ActiveRecord::Base
  validates_presence_of :url

  has_many :requests

  after_create :create_slug

  def create_slug
    self.update(slug: self.id.base62_encode)
  end
end

class Request < ActiveRecord::Base
  validates_presence_of :redirect_id

  belongs_to :redirect
end

get '/' do
  @redirects = Redirect.all.limit(25).order('created_at DESC')
  # @pusher_api_key = Pusher.key
  
  erb :index
end

get '/analytics' do
  @today = Date.today
  @reach = DateTime.parse(Chronic.parse('7 days ago').to_s).to_date
  @main = Request.find_by_sql("SELECT to_char(created_at, 'DDD') AS dayofyear, COUNT(1) FROM requests WHERE to_char(created_at, 'YYYY-MM-DD') BETWEEN '#{@reach}' AND '#{@today}' GROUP BY to_char(created_at, 'DDD');")
  @requests = {} # Request.find_by_sql("SELECT COUNT(redirects.slug) AS count, redirects.url, redirects.slug FROM requests LEFT JOIN redirects ON requests.redirect_id=redirects.id GROUP BY requests.redirect_id, redirects.url, redirects.slug ORDER BY count DESC;")
  @browsers = Request.find_by_sql("SELECT COUNT(requests.browser) AS count, requests.browser AS name FROM requests GROUP BY requests.browser ORDER BY count DESC;")
  @platforms = Request.find_by_sql("SELECT COUNT(requests.platform) AS count, requests.platform AS name FROM requests GROUP BY requests.platform ORDER BY count DESC;")
  @total_requests = Request.all.count
  #@main = DataMapper.repository(:default).adapter.select("select to_char(created_at, 'DDD') as dayofyear, count(1) from activities where to_char(created_at, 'YYYY-MM-DD') between '#{@reach}' and '#{@today}' group by to_char(created_at, 'DDD');")
  #@activities = DataMapper.repository(:default).adapter.select("SELECT COUNT(activities.fracture_id) AS count, fractures.url,fractures.encoded_uri FROM activities INNER JOIN fractures ON activities.fracture_id=fractures.id GROUP BY activities.fracture_id,fractures.url,fractures.encoded_uri ORDER BY count DESC;")
  #@browsers = DataMapper.repository(:default).adapter.select("SELECT COUNT(activities.browser) AS count,activities.browser AS name FROM activities GROUP BY activities.browser ORDER BY count DESC;")
  #@platforms = DataMapper.repository(:default).adapter.select("SELECT COUNT(activities.platform) AS count,activities.platform AS name FROM activities GROUP BY activities.platform ORDER BY count DESC;")
  erb :'analytics/index', :layout => :'layouts/admin.html'
end

get '/analytics/:slug' do
  @redirect = Redirect.find_by_slug(params[:slug])

  @today = Date.today
  @reach = DateTime.parse(Chronic.parse('7 days ago').to_s).to_date

  @main = Request.find_by_sql("SELECT to_char(created_at, 'DDD') AS dayofyear, COUNT(1) FROM requests WHERE to_char(created_at, 'YYYY-MM-DD') BETWEEN '#{@reach}' AND '#{@today}' AND redirect_id='#{@redirect.id}' GROUP BY to_char(created_at, 'DDD');")
  @requests = {} # Request.find_by_sql("SELECT COUNT(redirects.slug) AS count, redirects.url, redirects.slug FROM requests LEFT JOIN redirects ON requests.redirect_id=redirects.id GROUP BY requests.redirect_id, redirects.url, redirects.slug ORDER BY count DESC;")
  @browsers = Request.find_by_sql("SELECT COUNT(requests.browser) AS count, requests.browser AS name FROM requests WHERE redirect_id='#{@redirect.id}' GROUP BY requests.browser ORDER BY count DESC;")
  @platforms = Request.find_by_sql("SELECT COUNT(requests.platform) AS count, requests.platform AS name FROM requests WHERE redirect_id='#{@redirect.id}' GROUP BY requests.platform ORDER BY count DESC;")

  @requests = {}
  @total_requests = 1000

  erb :'analytics/show', layout: :'layouts/admin.html'
end

get '/documentation/api' do
  erb :api, layout: :'layouts/admin.html'
end

get '/documentation/encoding' do
  erb :encoding, layout: :'layouts/admin.html'
end

get '/:slug' do
  @redirect = Redirect.find_by_slug(params[:slug])

  if !@redirect.nil?
    begin
      user_agent = UserAgent.parse(request.env['HTTP_USER_AGENT'])

      Request.create!(
        :redirect_id  => @redirect.id,
        :ip           => request.env['REMOTE_ADDR'],
        :browser      => user_agent.browser,
        :version      => user_agent.version.to_s, # .to_s.gsub(/[^0-9|.]/,'').split('.')[0].to_i,
        :platform     => user_agent.platform,
        :is_mobile    => user_agent.mobile?
      )
    end
    redirect @redirect.url
  else
    erb :not_found, :layout => false
  end
end

post '/expand/:slug' do
  content_type :json

  begin
    @redirect = Redirect.find_by_slug(params[:slug])
    doc = Nokogiri::HTML(open(@redirect.url))

    response = {}
    response[:product_name] = doc.css('#ProductDetails h1')[0].content.strip rescue ''
    response[:main_image] = ''
    if doc.css('.main-image').present?
      response[:main_image] = doc.css('.main-image')[0]['src']
    elsif doc.css('.ProductThumbImage img').present?
      response[:main_image] = doc.css('.ProductThumbImage img')[0]['src']
    end
    response[:product_price] = doc.css('.ProductPrice')[0].content.strip rescue ''

    puts response

    raise 'Nothing Found' if response[:product_name].blank? && response[:product_name].blank? && response[:product_name].blank?

    return response.to_json
  rescue Exception => e
    status 400
    puts "Error #{e}"
    { errors: e }.to_json
  end
end

post '/sandbox' do
  content_type :json

  { bigcom_url: "http://bigcom.co/#{params[:url]}", errors: '' }.to_json
end

post '/' do
  content_type :json
  
  redirect = Redirect.new(
    url: params[:url]
  )
    
  if redirect.save
    { bigcom_url: "http://bigcom.co/#{redirect.slug}", errors: '' }.to_json
  else
    { bigcom_url: '', errors: redirect.errors.full_messages }.to_json
  end
end
