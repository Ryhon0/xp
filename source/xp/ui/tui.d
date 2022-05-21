module xp.ui.tui;

import termbox.keyboard;
import std.algorithm;
import termbox.color;
import xp.platforms;
import xp.library;
import std.string;
import xp.player;
import std.stdio;
import std.conv;
import termbox;

enum State
{
	SelectSong,
	Player
}

void putString(string s, int x, int y, ushort fg = Color.white, ushort bg = Color.black)
{
	for (int i = 0; i < s.length; i++)
	{
		setCell(x + i, y, s[i], fg, bg);
	}
}

void tui()
{
	string getSlider(int barsize)
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

		barsize -= posstr.length - lenstr.length - 2;

		import std.algorithm;

		int barl = cast(int)(getPosition() / getLength() * barsize);
		int barr = barsize - barl - 1;

		string stringmul(string s, int c)
		{
			string r = "";
			for (int i = 0; i < c; i++)
				r ~= s;
			return r;
		}

		return posstr ~ " " ~ stringmul("=", min(barl, barsize - 1)) ~ "o" ~ stringmul("-", barr) ~ " " ~ lenstr;
	}

	State state = State.SelectSong;

	init();
	scope (exit)
		shutdown();

	SongInfo[] songs;
	int selection = 0;
	void selectSong()
	{
		songs = getSongs();
		selection = 0;
		state = State.SelectSong;
	}

	selectSong();
	setVolume(0.2);
	SongInfo currentSong;

	while (1)
	{
		switch (state)
		{
		case State.SelectSong:
			{
				setClearAttributes(Color.white, Color.black);
				clear();

				if (songs.length)
				{
					for (int i = 0; i < songs.length; i++)
					{
						SongInfo song = songs[i];
						string text = song.author ~ " - " ~ song.title;

						ushort fg = Color.white;
						int x = 1;
						if (i == selection)
						{
							fg |= Attribute.underline;
							x++;
						}

						putString(text, x, 1 + i, fg, Color.black);
					}
					setCell(1, selection + 1, '>', Color.red, Color.black);
				}
				else
				{
					putString("No songs found, use 'xp add <uri>' to add them", 1, 1, Color.red, Color.black);
					putString("Press Q or ESC to exit", 1, 2, Color.red, Color.black);
				}

				flush();
				Event e;
				peekEvent(&e, 1);

				if(songs.length)
				{
					if (e.key == Key.arrowUp)
					{
						selection = clamp(selection - 1, 0, cast(int) songs.length - 1);
					}
					else if (e.key == Key.arrowDown)
					{
						selection = clamp(selection + 1, 0, cast(int) songs.length - 1);
					}
					else if (e.key == Key.enter)
					{
						SongInfo song = songs[selection];
						currentSong = song;
						string file = getSongFile(song);
						playFile(file.toStringz);
						seek(0);
						resume();
						state = State.Player;
					}
				}
				if (e.key == Key.esc || e.ch == 'q')
					return;

				break;
			}
		case State.Player:
		default:
			{
				setClearAttributes(Color.white, Color.black);
				clear();
				int w = width();
				int h = height();

				/// Progress
				string s = getSlider(w - 16);
				putString(s, 2, h - 2, Color.white, Color.black);

				// Volume
				for (int i = 0; i < h - 2; i++)
					setCell(0, i + 1, ((cast(float)((h - 4) - i) / (h - 4)) <= getVolume()) ? '#' : '|', Color.white, Color
							.black);

				// Song name
				string songname = currentSong.author ~ " - " ~ currentSong.title;
				putString(songname, 2, h-3, Color.white, Color.black);

				// Bottom row info
				string info = "^/v Volume  </> Seek  _ Play/Pause  C Change song  Q Exit";
				putString(info, 0, h - 1, Color.black, Color.white);

				flush();
				Event e;
				peekEvent(&e, 1);

				float voloffset = 0.02;
				if (e.key == Key.arrowUp || e.ch == '+')
				{
					setVolume(getVolume() + voloffset);
				}
				else if (e.key == Key.arrowDown || e.ch == '-')
				{
					setVolume(getVolume() - voloffset);
				}
				else if (e.key == Key.arrowRight)
				{
					seek(getPosition() + 1);
				}
				else if (e.key == Key.arrowLeft)
				{
					seek(getPosition() - 1);
				}
				else if (e.key == Key.space)
				{
					togglePause();
				}
				else if (e.ch == 'c')
				{
					selectSong();
				}
				else if (e.key == Key.esc || e.ch == 'q')
					return;

				if (isFinished())
					selectSong();
				break;
			}
		}

		import xp.mpris;
		mprisPoll();
	}
}
