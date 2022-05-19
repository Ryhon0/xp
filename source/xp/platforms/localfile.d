module xp.platforms.localfile;

import xp.platforms;
import std.stdio;

class LocalfilePlatform : PlatformProvider
{
	override bool canHandle(string uri)
	{
		import std.algorithm;

		if (uri.startsWith("file://"))
			return true;

		import std.file;

		return exists(uri);
	}

	override SongInfo getSongInfo(string uri)
	{
		// TODO: Audio metadata
		import std.array;

		SongInfo si = new SongInfo();
		si.uri = uri;
		si.title = uri.split("/")[$ - 1];

		return si;
	}

	override string getDownload(string uri)
	{
		import std.algorithm;

		if(!uri.startsWith("file://"))
			uri = "file://" ~ uri;

		return uri;
	}
}
