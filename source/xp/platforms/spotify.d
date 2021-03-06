module xp.platforms.spotify;

import xp.platforms.youtube;
import xp.platforms;
import std.string;
import std.regex;

class SpotifyPlatform : PlatformProvider
{
	mixin RegisterPlatformProvider;

	string id = "spotify";

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

		Arrogant arr = Arrogant();

		string html = get(uri).to!string;
		Tree tree = arr.parse(html);
		Node head = tree.head();

		string getOGValue(string key)
		{
			Node n = head.byAttribute("property", key)[0];
			return n["content"].get;
		}

		SongInfo si = new SongInfo();

		si.uri = uri;
		si.id = getId(uri);
		si.provider = this.id;

		si.title = getOGValue("og:title");
		si.author = getOGValue("og:description").split(" · ")[0];

		import std.file;
		import standardpaths;
		string coverdir = writablePath(StandardPath.data, FolderFlag.create) ~ "/xp/covers/";
		if (!exists(coverdir))
			mkdir(coverdir);
		string coverpath = coverdir ~ si.id ~ ".jpg";
		import std.net.curl;
		download(getOGValue("og:image"), coverpath);
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

		string tmpdir = writablePath(StandardPath.cache, FolderFlag.create) ~ "/xp/"; 
		if (!exists(tmpdir))
			mkdir(tmpdir);

		string query = si.author ~ " - " ~ si.title;

		string[] args;
		if(isYtDlpInstalled())
			args ~= ["yt-dlp", "--sponsorblock-remove=music_offtopic"];
		else args ~= "youtube-dl";

		auto jsonstr = execute(args ~ ["--print-json", "-f", "bestaudio", "--no-playlist",
			"--recode-video", "ogg", "--embed-metadata", "-o", tmpdir ~ "%(id)s.%(ext)s", "ytsearch:"~query
		]).output;
	
		JSONValue json = parseJSON(jsonstr);
		string filepath = json["_filename"].str;
		ulong exlen = extension(filepath).length;
		filepath = filepath[0 .. $ - exlen] ~ ".ogg";

		string filename = baseName(filepath);

		string datadir = writablePath(StandardPath.data, FolderFlag.create) ~ "/xp/songs/";
		if (!exists(datadir))
			mkdir(datadir);

		rename(filepath, datadir ~ filename);
		filepath = datadir ~ filename;

		// Embed spotify metadata
		import tag;
		TagLib_File* f = taglib_file_new(filepath.toStringz);
		TagLib_Tag* t = taglib_file_tag(f);
		taglib_tag_set_title(t, si.title.toStringz);
		taglib_tag_set_artist(t, si.author.toStringz);
		// No album art in taglib_c :(
		taglib_file_save(f);
		
		taglib_tag_free_strings();
		taglib_file_free(f);

		return filepath;
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
