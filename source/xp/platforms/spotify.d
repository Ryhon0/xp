module xp.platforms.spotify;

import xp.platforms;
import std.regex;
import std.stdio;

class SpotifyPlatform : PlatformProvider
{
	auto songRegex = ctRegex!r"^http[s]:\/\/open.spotify.com\/track\/(?P<id>[^?]*)";
	override bool canHandle(string uri)
	{
		auto m = matchFirst(uri, songRegex);
		if (m["id"])
			writeln("Matched spotify track " ~ m["id"]);
		return !m.empty;
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

		return si;
	}

	override string getDownload(string uri)
	{
		return uri;
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
