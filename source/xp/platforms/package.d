module xp.platforms;

PlatformProvider[] providers;

abstract class PlatformProvider
{
	const string id;
	abstract bool canHandle(string uri);
	abstract string getId(string uri);
	abstract SongInfo getSongInfo(string uri);
	abstract string downloadFile(string uri);
}

class SongInfo
{
	import xp.library : DBVersion, DBKey;

	string title;
	string author;
	string uri;
	string file;
	@DBKey string id;
	@DBKey string provider;
	@DBVersion(1) string thumbnail;
}

template RegisterPlatformProvider()
{
	static this()
	{
		import xp.platforms;
		providers ~= new typeof(this)();
	}
}

PlatformProvider getProvider(string providerid)
{
	foreach(p; providers)
		if(p.id == providerid)
			return p;
	
	return null;
}

PlatformProvider autoGetProviderForURI(string uri)
{
	foreach(p; providers)
		if(p.canHandle(uri))
			return p;
	
	return null;
}