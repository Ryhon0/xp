module xp.platforms.soundcloud;

import xp.platforms;
import std.stdio;
import std.regex;

class SoundCloudPlatform : PlatformProvider
{
	auto playlistRegex = ctRegex!r"^http[s]?:\/\/soundcloud.com\/(?P<user>.*)\/sets\/(?P<playlist>.*)";
	auto songRegex = ctRegex!r"^http[s]?:\/\/soundcloud.com\/(?P<user>.*)\/(?P<song>.*)";

	override bool canHandle(string uri)
	{
		auto m = matchFirst(uri, songRegex);
		if (m["song"])
			writeln("Matched soundcloud song " ~ m["user"] ~ "/" ~ m["song"]);
		return !m.empty;
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

		return si;
	}

	override string getDownload(string uri)
	{
		import std.process;

		return execute(["youtube-dl", "--get-url" , "-f", "bestaudio", uri]).output;
	}
}
