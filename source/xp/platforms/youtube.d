module xp.platforms.youtube;
import xp.platforms;
import std.regex;
import std.stdio;

class YoutubePlatform : PlatformProvider
{
	/// https://stackoverflow.com/a/37704433
	auto videoRegex = ctRegex!r"^((?:https?:)?\/\/)?((?:www|m)\.)?((?:youtube(-nocookie)?\.com|youtu.be))(\/(?:[\w\-]+\?v=|embed\/|v\/)?)(?P<id>[\w\-]+)(\S+)?$";
	override bool canHandle(string uri)
	{
		auto m = matchFirst(uri, videoRegex);
		if (m["id"])
			writeln("Matched youtube video " ~ m["id"]);
		return !m.empty;
	}

	override SongInfo getSongInfo(string uri)
	{
		import std.net.curl;
		import std.conv;
		import std.json;

		string json = get("https://www.youtube.com/oembed?url=" ~ uri).to!string;
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
