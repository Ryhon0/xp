module xp.platforms.localfile;

import xp.platforms;

class LocalfilePlatform : PlatformProvider
{
	mixin RegisterPlatformProvider;

	string id = "localfile";

	override bool canHandle(string uri)
	{
		import std.algorithm;

		if (uri.startsWith("file://"))
			return true;

		import std.file;

		return exists(uri);
	}

	override string getId(string uri)
	{
		return uri;
	}

	override SongInfo getSongInfo(string uri)
	{
		// TODO: Audio metadata
		import std.algorithm;
		import std.string;
		import std.array;
		import std.path;
		import std.conv;
		import tag;

		string file = uri;
		if(file.startsWith("file://"))
			file = file[7..$];

		SongInfo si = new SongInfo();
		si.uri = uri;

		TagLib_File* f = taglib_file_new(file.toStringz);
		TagLib_Tag* t = taglib_file_tag(f);
		if(t != null)
		{
			si.title = taglib_tag_title(t).to!string;
			si.author = taglib_tag_artist(t).to!string;
		}

		taglib_tag_free_strings();
		taglib_file_free(f);

		if(!si.title.length) si.title = baseName(file);
		if(!si.author.length) si.author = "unknown";

		si.provider = "localfile";
		si.id = getId(uri);

		return si;
	}

	override string downloadFile(string uri)
	{
		import std.algorithm;

		if(uri.startsWith("file://"))
			uri = uri[7..$];

		return uri;
	}
}
