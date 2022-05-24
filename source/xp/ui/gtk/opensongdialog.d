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

		PlatformProvider prov = autoGetProviderForURI(uri);

		if(prov is null)
		{
			destroy();
			return;
		}
		SongInfo si = prov.getSongInfo(uri);
		string file = prov.downloadFile(si);

		import xp.player;
		import std.string;
		playFile(file.toStringz);
		resume();

		destroy();
	}
}