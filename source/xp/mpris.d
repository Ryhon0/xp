module xp.mpris;

import xp.player;
import ddbus;
import app;

Connection dbusconn;
void registerMpris()
{
	dbusconn = connectToBus();
	MessageRouter router = new MessageRouter();

	auto mp2i = new MediaPlayer2();
	registerMethods(router, "/org/mpris/MediaPlayer2", "org.mpris.MediaPlayer2", mp2i);

	auto mp2pi = new MediaPlayer2Player();
	registerMethods(router, "/org/mpris/MediaPlayer2", "org.mpris.MediaPlayer2.Player", mp2pi);

	registerRouter(dbusconn, router);
	requestName(dbusconn, "org.mpris.MediaPlayer2.xp", NameFlags.AllowReplace);
}

// Poll dbus calls
void mprisPoll()
{
	tick(dbusconn);
}

class MediaPlayer2
{
	void Raise()
	{
	}

	void Quit()
	{
	}
}

class MediaPlayer2Player
{
	void Play()
	{
		resume();
	}

	void Pause()
	{
		pause();
	}

	void PlayPause()
	{
		togglePause();
	}

	void Seek(long posusec)
	{
		double pos = posusec / 1000.0;
		seek(pos);
	}
}