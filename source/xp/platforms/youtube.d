module xp.platforms.youtube;
import xp.platforms;
import std.regex;

string getYoutubeDL()
{
	string which(string prog)
	{
		import std.process;
		import std.array;
		import std.file;

		string[] paths = environment.get("PATH", "").split(':');
		foreach (path; paths)
		{
			string exepath = path ~ "/" ~ prog;
			import std.stdio;
			if (exists(exepath))
				return exepath;
		}

		return null;
	}

	string path = which("yt-dlp");
	if(!path) path = which("youtube-dl");

	return path;
}

bool isDLP(string path)
{
	import std.string : endsWith;
	return path.endsWith("yt-dlp");
}

class YoutubePlatform : PlatformProvider
{
	mixin RegisterPlatformProvider;

	string id = "spotify";

	/// https://stackoverflow.com/a/37704433
	auto videoRegex = ctRegex!r"^((?:https?:)?\/\/)?((?:www|m|music)\.)?((?:youtube(-nocookie)?\.com|youtu.be))(\/(?:[\w\-]+\?v=|embed\/|v\/)?)(?P<id>[\w\-]+)(\S+)?$";
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

		si.uri = uri;
		si.id = getId(uri);
		si.provider = "youtube";

		si.title = j["title"].str;
		si.author = j["author_name"].str;
		import std.algorithm;

		if (si.author.endsWith(" - Topic"))
			si.author = si.author[0 .. $ - " - Topic".length];

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
		string tmpdir = writablePath(StandardPath.cache, FolderFlag.create) ~ "/xp/";
		if (!exists(tmpdir))
			mkdir(tmpdir);

		string[] args;
		string exe = getYoutubeDL();
		args ~= exe;

		if (exe.isDLP)
			args ~= "--sponsorblock-remove=music_offtopic";

		auto jsonstr = execute(args ~ [
				"--print-json", "-f", "bestaudio", "--no-playlist",
				"--recode-video", "ogg", "--embed-metadata", "-o",
				tmpdir ~ "%(id)s.%(ext)s", uri
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
