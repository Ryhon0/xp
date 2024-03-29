module xp.platforms.soundcloud;

import xp.platforms;
import std.regex;

class SoundCloudPlatform : PlatformProvider
{
	mixin RegisterPlatformProvider;

	string id = "soundcloud";

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

		return song ~ "@" ~ user;
	}

	override SongInfo getSongInfo(string uri)
	{
		import std.net.curl;
		import std.conv;
		import std.json;

		string json = get("https://soundcloud.com/oembed?format=json&url=" ~ uri).to!string;
		JSONValue j = parseJSON(json);

		SongInfo si = new SongInfo();

		si.uri = uri;
		si.id = getId(uri);
		si.provider = this.id;

		si.author = j["author_name"].str;
		si.title = j["title"].str[0 .. $ - si.author.length - 4];
		
		import std.file;
		import standardpaths;
		string coverdir = writablePath(StandardPath.data, FolderFlag.create) ~ "/xp/covers/";
		if (!exists(coverdir))
			mkdir(coverdir);
		string coverpath = coverdir ~ si.id ~ ".jpg";
		import std.net.curl;
		download(j["thumbnail_url"].str, coverpath);
		si.thumbnail = coverpath;

		return si;
	}

	override string downloadFile(SongInfo si)
	{
		import std.process;
		import std.string;
		import std.array;
		import std.algorithm;

		import std.json;
		import std.path;

		import standardpaths;
		import std.file;

		string uri = si.uri;

		string datadir = writablePath(StandardPath.data, FolderFlag.create) ~ "/xp/songs/";
		if (!exists(datadir))
			mkdir(datadir);

		import xp.platforms.youtube : getYoutubeDL;
		auto jsonstr = execute([
			getYoutubeDL, "--print-json", "-f", "bestaudio",
			"--embed-metadata", "-o", datadir ~ "%(id)s.%(ext)s", uri
		]).output;

		JSONValue json = parseJSON(jsonstr);
		return json["_filename"].str;
	}
}
