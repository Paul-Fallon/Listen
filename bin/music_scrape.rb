
require 'nokogiri'
require 'open-uri'
require "net/http"

#PROBLEMS:
# 1) Large names like "Alice In Chains" + "Man In The Box" return too many values
# 2) Need to also test for no spaces in filename - "Green Day, Long View" misses "...longview.mp3"
# 3) When getting names, need to also gsub "+" if the links don't use %20 for spaces

#TODO: 
# 1) Write ID3 tags
# 2) Get Album and Cover
# 3) Pick a "best song", somehow reference song length or file size to get best match or else pick the largest one




#pass artist + song
class Song_By_Artist
	def initialize(link,name,size)
		@link = link
		@name = name
		@size = size
	end
	def name
		return @name
	end
	def link
		return @link
	end
	def size
		return @size
	end
end

module Scraper 

	def Scraper.scrape(artist, song)

	song_array = []

	preterms = "#{artist}+#{song}"
	terms = preterms.gsub!(/\s/,'+')
	url = "http://www.google.com/search?q=intitle%3Aindex.of%3Fmp3+#{terms}&oq=intitle%3Aindex.of%3Fmp3+#{terms}&aqs=chrome..69i57.765j0j4&sourceid=chrome&es_sm=91&ie=UTF-8"
	doc = Nokogiri::HTML(open(url))

	# Search for nodes by xpath
	count = 0
	dirty_result_urls = []

	#Grabs google search results
	doc.xpath("//h3[@class='r']/a/@href").each do |link|
		#Gets the link
		result = link.content
		long_result_url = URI.extract(result)
		#puts long_result_url
		url_string = long_result_url.to_s
		short_url_string = url_string.split("&sa")
		short_url_string = short_url_string[0].split("[\"")
		#puts short_url_string[0]
		dirty_result_urls[count] = short_url_string[1]
		#puts result_urls[count]
		count = count + 1
	end

	puts "\nDomains pulled from the search: "

	(0...dirty_result_urls.length).each do |i|
		puts dirty_result_urls[i]
	end

	result_urls = []
	(0...dirty_result_urls.length).each do |i|
	# 		url = URI.parse(dirty_result_urls[i])
		# req = Net::HTTP.new(url.host, url.port)
		# begin
		# res = req.request_head(url.path)
		# rescue Errno::ENETUNREACH => e
	#   	puts "Can't access that shit"
	#    	puts e
	#    	next
		#end
		#puts res.code
		#if res.code == "200"
			result_urls.push(dirty_result_urls[i])
		#end
	end 

	(0...result_urls.length).each do |i|
		puts result_urls[i]
	end


	test = terms.split('+')
	puts test



	puts "\n########################\n"

	songs_by_artist = []

	(0...result_urls.length).each do |i|
		begin
			puts result_urls[i]
			result_doc = Nokogiri::HTML(open(result_urls[i]))
		rescue OpenURI::HTTPError, Errno::ENETUNREACH, Errno::ETIMEDOUT, Net::ReadTimeout, Errno::ECONNREFUSED => e
			puts "YOU DUN SCREWED UP"
	 		puts e
	 	next
		end


		result_doc.xpath("/html/body/ul/li/a/@href").each do |link|
			if test.any? { |word| link.content.to_s.include?(word) }
				puts "#{result_urls[i]}#{link.content}"
				song_link = "#{result_urls[i]}#{link.content}"
				songs_by_artist.push(song_link)
			end
		end
		result_doc.xpath("/html/body/pre/a/@href").each do |link|
			if test.any? { |word| link.content.to_s.include?(word) }
				puts "#{result_urls[i]}#{link.content}"
				song_link = "#{result_urls[i]}#{link.content}"
				songs_by_artist.push(song_link)
			end
		end
		result_doc.xpath("//td/a/@href").each do |link|
			if test.any? { |word| link.content.to_s.include?(word) }
				puts "#{result_urls[i]}#{link.content}"
				song_link = "#{result_urls[i]}#{link.content}"
				songs_by_artist.push(song_link)
			end
		end


	end

	puts "\n########################\n"
	puts "All Songs Found"
		puts songs_by_artist

		puts "\n########################\n"
		puts "Matched Songs"
		songsies = song.split(' ')

		matches = []

		(0...songs_by_artist.length).each do |i|
			if songsies.all? { |word| songs_by_artist[i].include?(word) }
				puts "#{songs_by_artist[i]}"
				song_match = songs_by_artist[i]
				matches.push(song_match)
			end
		end

		#Looking for 302 redirect, 401 no access

		clean_matches = []
		clean_names = []
		file_sizes =[]
		(0...matches.length).each do |i|
		url = URI.parse(matches[i])
		req = Net::HTTP.new(url.host, url.port)
		begin
			res = req.request_head(url.path)
		rescue URI::InvalidURIError	=> e
			puts "YOU DUN SCREWED UP"
	 		puts e
	 	next
		end 
		puts res.code
		if res.code == "200"
			clean_matches.push(matches[i])
		end
	end 

	#Clear Screen
	system("clear")

	puts "########################\n"

	puts "Your Song:\n\n"


	song_array_success = 0
	(0...clean_matches.length).each do |i|
		#Parse URL
		url = URI.parse(clean_matches[i])
		req = Net::HTTP.new(url.host, url.port)
		response = req.request_head(clean_matches[i])
		file_size = response['content-length'].to_i   #Get File size
		ext = clean_matches[i].split('/')[-1]	#Split url at last slash
		clean_names[i] = ext.gsub!(/%20/,' ')	#Substitute %20 (space in url) for a space
		#clean_names[i] = ext.gsub!(/\+/,' ')	#Substitute + (space in url) for a space
		#Size of a mb is 1,048,576, bytes/that = mb
		file_sizes[i] = file_size/1048576.0
		if file_sizes[i] > 0.1
			puts "#{file_sizes[i]} MB --- #{clean_names[i]}"	#Display file size and clean name
			puts "#{clean_matches[i]}\n\n"	#Display URL
			song_array[song_array_success] = Song_By_Artist.new(clean_matches[i],clean_names[i],file_sizes[i])
			song_array_success += 1
		end

	end

	puts "OBJECTS"
	(0...song_array.length).each do |i|
		puts "#{song_array[i].size} MB --- #{song_array[i].name}"
		puts "#{song_array[i].link}\n\n"
	end

	return song_array

	end

end



