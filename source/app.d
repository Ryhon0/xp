import bindbc.sdl;
import std.stdio;
import std.conv;
import std.json;

int main(string[] args)
{
	import xp.player;

	playerInit();

	import xp.library;

	libraryInit();

	import xp.mpris;

	registerMpris();

	if (args.length > 1)
	{
		string cmd = args[1];

		if (cmd == "list")
		{
			import std.conv;

			foreach (i, s; getSongs())
			{
				writeln(i.to!string ~ ". " ~ s.author ~ " - " ~ s.title);
			}
			return 0;
		}
		
		if (cmd == "add")
		{
			string uri = args[2];

			import xp.platforms;
			import xp.platforms.localfile;
			import xp.platforms.youtube;
			import xp.platforms.spotify;
			import xp.platforms.soundcloud;

			PlatformProvider prov = autoGetProviderForURI(uri);

			if (prov is null)
				return 1;
			
			SongInfo si = prov.getSongInfo(uri);
			writeln("Downloading " ~ si.author ~ " - " ~ si.title);
			si.file = prov.downloadFile(si);

			addSong(si);

			return 0;
		}

		// Fetches all the songs again
		if(cmd == "refreshall")
		{
			import xp.platforms;
			SongInfo[] songs = getSongs();
			foreach(s; songs)
			{
				writeln("Refreshing " ~ s.author ~ " - " ~ s.title ~ " (" ~ s.uri ~ ")");
				PlatformProvider provider = autoGetProviderForURI(s.uri);
				if(provider is null)
				{
					writeln("Could not find provider for " ~ s.uri);
					continue;
				}

				SongInfo newSi = provider.getSongInfo(s.uri);
				if(newSi.file != null)
				{
					writeln("Downloading...");
					newSi.file = provider.downloadFile(newSi);
				}

				removeSong(s);
				addSong(newSi);
			}
			return 0;
		}

		if(cmd == "tui")
		{
			import xp.ui.tui;
			tui();
			return 0;
		}
	}

	import xp.ui.gtk.mainwindow;
	import gio.Application : GioApplication = Application;
	import gtk.Application;

	auto application = new Application("link.ryhn.xp", GApplicationFlags.FLAGS_NONE);
	application.addOnActivate(delegate void(GioApplication app) {
		auto win = new MainWindow(application);
		win.show();
	});
	return application.run([]);
}
