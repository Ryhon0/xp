module mainwindow;

import app;

import gtk.ApplicationWindow;
import gtk.VolumeButton;
import gtk.ScaleButton;
import gtk.Application;
import glib.Timeout;
import gtk.IconView;
import gtk.Button;
import gtk.Label;
import gtk.Scale;
import gtk.Range;
import xp.player;
import gtk.Box;


class MainWindow : ApplicationWindow
{
	static MainWindow instance;

	VolumeButton volumeButton;
	Label positionLabel;
	Scale positionScale;
	IconView pauseIcon;
	Button pauseButton;
	Label lengthLabel;
	Box box;

	int secLength = 0;
	bool isUpdate = 0;

	this(Application app)
	{
		super(app);
		instance = this;

		Timeout.add(10, &update, null);

		setTitle("XP");
		setSizeRequest(500, 50);

		box = new Box(Orientation.HORIZONTAL, 5);
		setChild(box);

		pauseButton = new Button();
		box.append(pauseButton);
		pauseButton.addOnClicked((Button b) { togglePause(); });

		positionLabel = new Label("0:00");
		box.append(positionLabel);

		positionScale = new Scale(Orientation.HORIZONTAL, 0, 20, 0.0001);
		box.append(positionScale);
		positionScale.setHexpand(true);
		positionScale.setHalign(GtkAlign.FILL);
		positionScale.addOnValueChanged((Range s) {
			// setValue emmits the OnValueChanged signal, so we need to ignore it if we're updating
			// Seems to work fine with MP3 files, but OGG creates crackling every time we seek
			if (isUpdate)
				return;

			seek(s.getValue());
		});

		lengthLabel = new Label("0:00");
		box.append(lengthLabel);

		volumeButton = new VolumeButton();
		box.append(volumeButton);
		volumeButton.setValue(1);
		volumeButton.addOnValueChanged((double v, ScaleButton s) {
			setVolume(s.getValue());
		});

		playFile("Alpha Dance.ogg");
	}
}

extern (C) int update(void* userData)
{
	import xp.mpris;
	mprisPoll();

	import std.conv;
	import std.string;

	MainWindow.instance.isUpdate = true;

	double pos = getPosition();
	MainWindow.instance.positionScale.setValue(pos);
	MainWindow.instance.pauseButton.setIconName(isPaused() ? "media-playback-start"
			: "media-playback-pause");
	MainWindow.instance.positionScale.setRange(0, getLength());

	int posmins = cast(int) pos / 60;
	int possecs = cast(int) pos % 60;

	int lenmins = MainWindow.instance.secLength / 60;
	int lensecs = MainWindow.instance.secLength % 60;

	string posstr = posmins.to!string() ~ ":" ~ (possecs.to!string()
			.rightJustifier(2, '0')).to!string;
	string lenstr = lenmins.to!string() ~ ":" ~ (lensecs.to!string()
			.rightJustifier(2, '0')).to!string;
	MainWindow.instance.positionLabel.setText(posstr);
	MainWindow.instance.lengthLabel.setText(lenstr);

	MainWindow.instance.isUpdate = false;
	return 1;
}
