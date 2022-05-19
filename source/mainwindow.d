module mainwindow;

import app;

import gtk.ApplicationWindow;
import gtk.ToggleButton;
import gtk.Application;
import gtk.ScaleButton;
import gtk.Button;
import gtk.Scale;
import gtk.Range;
import gtk.Box;
import glib.Timeout;

class MainWindow : ApplicationWindow
{
	static MainWindow instance;

	ScaleButton vol;
	ToggleButton b;
	Scale pos;
	Box box;
	this(Application app)
	{
		super(app);
		instance = this;

		Timeout.add(10, &update, null);

		setTitle("XP");
		setSizeRequest(500, 50);

		box = new Box(Orientation.HORIZONTAL, 5);
		setChild(box);

		b = new ToggleButton("Play/Pause");
		box.append(b);
		b.addOnClicked((Button b)
		{
			if(isPaused)
				resume();
			else
				pause();
		});

		pos = new Scale(Orientation.HORIZONTAL, 0, 20, 0.0001);
		box.append(pos);
		pos.setHexpand(true);
		pos.setHalign(GtkAlign.FILL);
		pos.addOnValueChanged((Range s)
		{
			seek(s.getValue());
		});

		vol = new ScaleButton(0,1,0.01,[]);
		vol.setIcons(["audio-volume-muted",
"audio-volume-high",
"audio-volume-low",
"audio-volume-medium",
"audio-volume-high"]);
		box.append(vol);
		vol.setValue(1);
		vol.addOnValueChanged((double v,ScaleButton s)
		{
			setVolume(s.getValue());
		});
	}
}

	extern(C) int update (void* userData)
	{
		MainWindow.instance.pos.setValue(getPosition());
		MainWindow.instance.b.setActive(isPaused());
		return 1;
	}