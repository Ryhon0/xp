module xp.platforms.spotify;

import xp.platforms.youtube;
import xp.platforms;
import std.string;
import std.regex;

class SpotifyPlatform : PlatformProvider
{
	mixin RegisterPlatformProvider;

	string id = "spotify";
	string accessToken = null;
	long tokenExpires = 0;

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
		string id = getId(uri);

		checkToken();

		import std.net.curl;
		import std.json;

		HTTP c = HTTP();
		c.addRequestHeader("Authorization", "Bearer " ~ accessToken);
		JSONValue j;
		try
		{
			j = parseJSON(get("https://api.spotify.com/v1/tracks/" ~ id, c));	
		}
		catch(Exception)
		{
			// Likely an invalid song ID
			return null;
		}
		
		SongInfo si = new SongInfo();

		si.uri = uri;
		si.id = id;
		si.provider = this.id;
		si.title = j["name"].str;
		si.author = j["artists"][0]["name"].str;
		si.author = j["artists"][0]["name"].str;

		import std.file;
		import standardpaths;

		string coverdir = writablePath(StandardPath.data, FolderFlag.create) ~ "/xp/covers/";
		if (!exists(coverdir))
			mkdir(coverdir);
		string coverpath = coverdir ~ si.id ~ ".jpg";
		import std.net.curl;

		download(j["album"]["images"][0]["url"].str, coverpath);
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
		if (isYtDlpInstalled())
			args ~= ["yt-dlp", "--sponsorblock-remove=music_offtopic"];
		else
			args ~= "youtube-dl";

		auto jsonstr = execute(args ~ [
				"--print-json", "-f", "bestaudio", "--no-playlist",
				"--recode-video", "ogg", "--embed-metadata", "-o",
				tmpdir ~ "%(id)s.%(ext)s", "ytsearch:" ~ query
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

	void checkToken()
	{
		import std.datetime.systime : Clock, SysTime;

		// Why is this the easiest way to get Unix time in msecs?
		long t = (Clock.currTime - SysTime.fromUnixTime(0)).total!"msecs";

		if (accessToken == null || t >= tokenExpires)
			getAccessToken();
	}

	void getAccessToken()
	{
		import std.net.curl;

		import std.json;

		JSONValue j = parseJSON(get("https://open.spotify.com/get_access_token"));
		accessToken = j["accessToken"].str;
		tokenExpires = j["accessTokenExpirationTimestampMs"].integer;
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
