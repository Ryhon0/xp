module xp.platforms.youtube;
import xp.platforms;
import std.regex;

class YoutubePlatform : PlatformProvider
{
	/// https://stackoverflow.com/a/37704433
	auto videoRegex = ctRegex!r"^((?:https?:)?\/\/)?((?:www|m)\.)?((?:youtube(-nocookie)?\.com|youtu.be))(\/(?:[\w\-]+\?v=|embed\/|v\/)?)(?P<id>[\w\-]+)(\S+)?$";
	override bool canHandle(string uri)
	{
		auto m = matchFirst(uri, videoRegex);
		return !m.empty;
	}

	override string getId(string uri)
	{
		auto m = matchFirst(uri, videoRegex);
		return m["id"];
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
		si.id = getId(uri);
		si.provider = "youtube";

		return si;
	}

	override string downloadFile(string uri)
	{
		import std.process;
		import std.string;
		import std.array;
		import std.algorithm;

		import std.json;
		import std.path;

		import standardpaths;
		import std.file;

		string tmpdir = writablePath(StandardPath.cache, FolderFlag.create) ~ "/xp/";
		if (!exists(tmpdir))
			mkdir(tmpdir);

		auto jsonstr = execute([
			"youtube-dl", "--print-json", "-f", "bestaudio", "--no-playlist",
			"--recode-video", "ogg", "--embed-metadata", "-o", tmpdir ~ "%(id)s.%(ext)s", uri
		]).output;

		JSONValue json = parseJSON(jsonstr);
		string filepath = json["_filename"].str;
		ulong exlen = extension(filepath).length;
		filepath = filepath[0 .. $ - exlen] ~ ".ogg";

		string filename = baseName(filepath);

		string datadir = writablePath(StandardPath.data, FolderFlag.create) ~ "/xp/songs/";
		if (!exists(datadir))
			mkdir(datadir);

		rename(filepath, datadir ~ "/" ~ filename);

		return datadir ~ filename;
	}
}
