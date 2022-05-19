module xp.platforms;

class PlatformProvider
{
	abstract bool canHandle(string uri);
	abstract SongInfo getSongInfo(string uri);
	abstract string getDownload(string uri);
}

class SongInfo
{
	string title;
	string author;
	string uri;
}