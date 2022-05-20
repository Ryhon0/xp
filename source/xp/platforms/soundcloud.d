module xp.platforms.soundcloud;

import xp.platforms;
import std.regex;

class SoundCloudPlatform : PlatformProvider
{
	auto playlistRegex = ctRegex!r"^http[s]?:\/\/soundcloud.com\/(?P<user>.*)\/sets\/(?P<playlist>.*)";
	auto songRegex = ctRegex!r"^http[s]?:\/\/soundcloud.com\/(?P<user>.*)\/(?P<song>.*)";

	override bool canHandle(string uri)
	{
		auto m = matchFirst(uri, songRegex);
		
		return !m.empty;
	}

	override string getId(string uri)
	{
		auto m = matchFirst(uri, songRegex);
		
		string user = m["user"];
		string song = m["song"];

		return user + "/" + song;
	}

	override SongInfo getSongInfo(string uri)
	{
		import std.net.curl;
		import std.conv;
		import std.json;

		string json = get("https://soundcloud.com/oembed?format=json&url=" ~ uri).to!string;
		JSONValue j = parseJSON(json);

		SongInfo si = new SongInfo();
		si.title = j["title"].str;
		si.author = j["author_name"].str;
		si.uri = uri;
		si.id = getId(uri);
		si.provider = "soundcloud";

		return si;
	}

	override string downloadFile(string uri)
	{
		import std.process;
		import std.string;

		import std.json;
		auto jsonstr = execute(["youtube-dl", "--print-json" , "-f", "bestaudio", uri]).output;
		JSONValue json = parseJSON(jsonstr);
		string filename = json["_filename"].str;
		
		return filename;
	}
}
