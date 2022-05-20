module xp.ui.gtk.opensongdialog;

import gtk.FileChooserDialog;
import gtk.Window;
import gtk.Button;
import gtk.Dialog;
import gtk.Label;
import gtk.Entry;
import gtk.Box;

class OpenSongDialog : Dialog
{
	this(Window parent)
	{
		super();
		setTransientFor(parent);
		Box box = new Box(GtkOrientation.VERTICAL, 0);
		setChild(box);
		
		Entry e = new Entry();
		box.append(e);

		Button b = new Button("Open");
		box.append(b);
		b.addOnClicked(delegate(Button b)
		{
			loadUri(e.getText());
		});

	}

	void loadUri(string uri)
	{
		import xp.platforms;	
		import xp.platforms.localfile;	
		import xp.platforms.youtube;	
		import xp.platforms.spotify;	
		import xp.platforms.soundcloud;

		PlatformProvider[] provs;
		PlatformProvider prov;

		provs ~= new YoutubePlatform();
		provs ~= new SpotifyPlatform();
		provs ~= new SoundCloudPlatform();
		provs ~= new LocalfilePlatform();

		foreach(candprov; provs)
		{
			if(candprov.canHandle(uri))
			{
				prov = candprov;
				break;
			}
		}

		if(prov is null)
		{
			destroy();
			return;
		}

		string file = prov.downloadFile(uri);

		import xp.player;
		import std.string;
		playFile(file.toStringz);
		resume();

		destroy();
	}
}