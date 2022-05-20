module xp.platforms.spotify;

import xp.platforms;
import std.regex;

class SpotifyPlatform : PlatformProvider
{
	auto songRegex = ctRegex!r"^http[s]:\/\/open.spotify.com\/track\/(?P<id>[^?]*)";
	override bool canHandle(string uri)
	{
		auto m = matchFirst(uri, songRegex);
		return !m.empty;
	}

	override string getId(string uri)
	{
		auto m = matchFirst(uri, songRegex);
		return m["id"];
	}

	override SongInfo getSongInfo(string uri)
	{
		import std.net.curl;
		import std.string;
		import std.conv;
		import arrogant;

		SongInfo si = new SongInfo();
		Arrogant arr = Arrogant();

		string html = get(uri).to!string;
		Tree tree = arr.parse(html);
		Node head = tree.head();

		string getOGValue(string key)
		{
			Node n = head.byAttribute("property", key)[0];
			return n["content"].get;
		}

		si.title = getOGValue("og:title");
		si.author = getOGValue("og:description").split(" · ")[0];
		si.uri = uri;
		si.id = getId(uri);
		si.provider = "spotify";

		return si;
	}

	override string downloadFile(string uri)
	{
		import std.process;
		import std.string;
		import std.array;
		import std.algorithm;

		SongInfo i = getSongInfo(uri);

		import std.json;
		import std.path;
		auto jsonstr = execute(["youtube-dl", "--print-json" , "-f", "bestaudio", "--recode-video", "ogg", 
			"ytsearch:" ~ i.author ~ " - " ~ i.title]).output;
		JSONValue json = parseJSON(jsonstr);
		string filename = json["_filename"].str;

		ulong exlen = extension(filename).length;
		return filename[0..$-exlen] ~ ".ogg";
	}
}

unittest
{
	SpotifyPlatform sp = new SpotifyPlatform();
	string url = "https://open.spotify.com/track/4kB8uLRcquqMiCdSnHOHjM?si=7b39886efa0047bd&nd=1";
	string title = "B L A C K - R A Y";
	string author = "Camellia";

	assert(sp.canHandle(url));

	SongInfo si = sp.getSongInfo(url);
	assert(si.title == title);
	assert(si.author == author);
}
