module xp.platforms;

abstract class PlatformProvider
{
	abstract bool canHandle(string uri);
	abstract string getId(string uri);
	abstract SongInfo getSongInfo(string uri);
	abstract string downloadFile(string uri);
}

class SongInfo
{
	string title;
	string author;
	string uri;
	string id;
	string provider;
}