module xp.ui.tui;

import xp.platforms;
import xp.library;
import std.string;
import xp.player;
import std.stdio;
import std.conv;

void tui()
{
	import arsd.terminal;

	auto terminal = Terminal(ConsoleOutputType.linear);
	auto input = RealTimeConsoleInput(&terminal, ConsoleInputFlags.raw);

	void selectSong()
	{
		SongInfo[] songs = getSongs();
		foreach (i, s; songs)
			writeln(i.to!string ~ " - " ~ s.author ~ " - " ~ s.title);

		int choice = terminal.getline("Enter song number: ").strip.to!int;

		SongInfo song = songs[choice];

		string file = getSongFile(song);
		playFile(file.toStringz);
		seek(0);
		resume();
	}

	void printPos()
	{
		import std.string;

		int posmins = cast(int) getPosition() / 60;
		int possecs = cast(int) getPosition() % 60;

		int lenmins = cast(int) getLength() / 60;
		int lensecs = cast(int) getLength() % 60;

		string posstr = posmins.to!string() ~ ":" ~ (possecs.to!string()
				.rightJustifier(2, '0')).to!string;
		string lenstr = lenmins.to!string() ~ ":" ~ (lensecs.to!string()
				.rightJustifier(2, '0')).to!string;
		
		import std.algorithm;
		int barsize = 40;
		int barl = cast(int)(getPosition() / getLength() * barsize);
		int barr = barsize - barl - 1;

		string stringmul(string s, int c)
		{
			string r = "";
			for(int i=0;i<c;i++)
				r ~= s;
			return r;
		}
		string bar = stringmul("=", min(barl, barsize-1)) ~ "◯" ~ stringmul("-", barr) ;

		writeln(posstr ~ " " ~ bar ~ " " ~ lenstr);
	}

	selectSong();
	while (1)
	{
		int ch = input.getch(true);
		if (ch == 983_077)
		{
			seek(getPosition() - 1);
			printPos();
		}
		if (ch == 983_079)
		{
			seek(getPosition() + 1);
			printPos();
		}
		float volumeOffset = 0.05;
		if (ch == 983_078 || ch == '+')
		{
			setVolume(getVolume() + volumeOffset);
			writeln(getVolume());
		}
		if (ch == 983_080 || ch == '-')
		{
			setVolume(getVolume() - volumeOffset);
			writeln(getVolume());
		}
		if (ch == ' ' || ch == 'p')
		{
			togglePause();
			writeln(isPaused() ? "Paused" : "Playing");
		}
		if (ch == 'l')
		{
			printPos();
		}
		if (ch == 'c')
		{
			pause();
			selectSong();
		}
		if (ch == 'q')
		{
			break;
		}

		if(isFinished())
			selectSong();
	}
}
