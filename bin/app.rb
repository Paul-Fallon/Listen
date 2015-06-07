require 'sinatra'
require './bin/music_scrape'


set :port, 8080
set :static, true
set :public_folder, "static"
set :views, "views"
set :public, 'public'

get '/index' do
  	erb :index
end

post '/index' do
	array = Scraper.scrape(params["#{:artist}"],params["#{:song}"])
 	erb :hello_form, :locals => {'array' => array, 'links' => array[0].link, 'names' => array[0].name, 'sizes' => array[0].size} || "Damn, Couldn't Find The Song"
end

not_found do
  	status 404
  	'not found'
end
