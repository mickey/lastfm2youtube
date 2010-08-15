require "rubygems"
require "json"
require "lib/youtube_it/lib/youtube_it"

username = "pada51"

config = YAML::load(File.open("config.yml"))

client = YouTubeIt::Client.new(config["youtube_username"], config["youtube_password"], config["youtube_api_key"])

playlist_name = username.gsub(/[^0-9A-Za-z]/, '')

doc = REXML::Document.new(client.playlists)
doc.root.elements.each("entry") do |e|
  if e.elements["title"].text == playlist_name
    playlist_id = e.elements["id"].text.split(":").last
    client.del_playlist(playlist_id)
    sleep(1.0)
  end
end

playlist = client.add_playlist({:title => "#{playlist_name}", :description => "blahblah", :private => false})
doc = REXML::Document.new(playlist[:body])
playlist_id = doc.elements["entry"].elements["id"].text.split(":").last

body = ""
Net::HTTP.start('ws.audioscrobbler.com', 80) do |http| 
  body = http.get("/2.0/?method=user.getlovedtracks&user=#{username}&api_key=#{config["lastfm_api_key"]}&format=json").body
end

loved_tracks = JSON.parse(body)

loved_tracks["lovedtracks"]["track"].each do |t|
  video = client.videos_by(:query => "#{t["artist"]["name"]} #{t["name"]}", :categories => [:music])
  if video.videos[0]
    video_id = video.videos[0].unique_id
    begin
      sleep(1.0)
      client.add_video_to_playlist(playlist_id, video_id)
    rescue
      next
    end
  end
end