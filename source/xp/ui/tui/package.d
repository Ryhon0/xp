module xp.ui.tui;

import xp.ui.tui.drawing;
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
	Player,
	SelectSong,
	AddSong
}

void tui()
{
	State state = State.SelectSong;

	init();
	scope (exit)
		shutdown();
	setInputMode(InputMode.esc | InputMode.mouse);
	setOutputMode(OutputMode.grayscale);

	void fullClear()
	{
		setClearAttributes(Color.black, Color.black);
		setClearAttributes(Color.black, Color.white);
		clear();
		flush();
	}

	SongInfo[] songs;
	int selection = 0;
	void selectSong()
	{
		state = State.SelectSong;
	}

	string addsonginput;
	wstring addsongError;
	void addSong()
	{
		state = State.AddSong;
		addsonginput = "";
		addsongError = "";
	}

	SongInfo currentSong;
	void selectCurrentSong()
	{
		SongInfo song = songs[selection];
		currentSong = song;
		string file = getSongFile(song);
		playFile(file.toStringz);
		seek(0);
		resume();
		state = State.Player;
		fullClear();
	}

	songs = getSongs();
	selectSong();
	setVolume(0.2);
	setOutputMode(OutputMode.normal);

	while (1)
	{
		setClearAttributes(Color.white, Color.black);
		clear();
		int w = width();
		int h = height();

		// Volume
		import std.algorithm.mutation;

		wchar[] volchars = verticalSmoothProgressChars.dup;
		wstring volbar = progressBar(1 - getVolume(), h - 1, volchars.reverse());
		putStringVertical(volbar, 0, 0, Color.green | Attribute.bright, Color.white);

		if (currentSong !is null)
		{
			/// Progress
			{
				int barsize = w - 4 - 10 - 4;
				float len = getLength();
				if (len == 0)
					len = 1;
				float pos = getPosition();

				int posmins = cast(int) pos / 60;
				int possecs = cast(int) pos % 60;

				int lenmins = cast(int) len / 60;
				int lensecs = cast(int) len % 60;

				import std.string;

				wstring posstr = (posmins.to!string() ~ ":" ~ (possecs.to!string()
						.rightJustifier(2, '0')).to!string).to!wstring;
				wstring lenstr = (lenmins.to!string() ~ ":" ~ (lensecs.to!string()
						.rightJustifier(2, '0')).to!string).to!wstring;

				int i = 4;
				putString(posstr, i, h - 2);
				i += posstr.length + 1;
				barsize -= posstr.length - lenstr.length - 2;

				bool smoothbar = true;
				if (smoothbar)
				{
					wstring bar;
					bar = progressBar(pos / len, barsize);
					putString(bar, i, h - 2, Color.blue | Attribute.bright, Color.white);
					i += bar.length + 1;
				}
				else
				{
					wstring bar;
					bar = progressBar(pos / len, barsize, ['─', '◯', '═']);
					putString(bar, i, h - 2, Color.blue | Attribute.bright, Color.black);
					i += bar.length + 1;
				}

				putString(lenstr, i, h - 2);
			}

			wstring status = isFinished() ? "■" : (isPaused() ? "▌▌" : "▶");
			putString(status, 2, h - 2);

			// Song name
			wstring songname = (currentSong.author ~ " - " ~ currentSong.title).to!wstring;
			putString(songname, 2, h - 3, Color.white, Color.black);
		}

		// Song list
		{
			int bh = currentSong is null ? h - 1 : h - 3;
			if (songs.length)
			{
				for (int i = 0; i < bh - 1; i++)
				{
					if (i == songs.length)
						break;

					int y = bh - 2 - i;
					int x = 3;
					SongInfo song = songs[i];
					ushort col = i % 2 == 0 ? Color.white : Color.black | Attribute.bright;
					ushort bg = Color.black;

					if (selection == i)
					{
						putString(">", x, y, Color.red | Attribute.bold, Color.black);
						x++;
					}

					if (currentSong !is null && currentSong.id == song.id)
						col |= Attribute.underline | Attribute.bold;

					import std.string;

					wstring songname = (song.author ~ " - " ~ song.title).to!wstring;
					putString(songname, x, y, col, bg);
				}
			}
			else
			{
				putString("No songs found", 3, bh - 3, Color.red, Color.black);
				putString("Use 'xp add <uri>' or press A to add songs", 3, bh - 2, Color.red, Color.black);
			}
			ushort bcol = state == State.SelectSong ? Color.white : Color.black | Attribute.bright;
			drawBox(2, 0, w - 4, bh, roundBoxChars, bcol);
			putString("Song list", 4, 0, bcol);

			import xp;
			wstring verstr = ("xp " ~ xpVersion).to!wstring;
			putString(verstr, cast(int)(w - verstr.length - 2), bh - 1, bcol);
		}

		// Add song window
		if (state == State.AddSong)
		{
			int bw = 50;
			int bh = 7;
			int x = (w/2) - (bw/2);
			int y = (h/2) - (bh/2);

			drawBox(x,y,bw,bh, singleLineBoxChars);
			clearBox(x+1,y+1,bw-2,bh-2);
			putString("Add song", x + 1, y);
			putString("URI:", x + 1, y + 2);
			wstring ws = addsonginput.to!wstring;
			putString(ws, x+1, y+3);
			setCursor(cast(int)(x + 1 + ws.length), y+3);
			putString(addsongError, x+1, y+4, Color.red);
		}
		else hideCursor();

		// Bottom row info
		wstring info;
		wstring[State] infos =
			[
				State.Player: " ↑↓ Volume  ←→ Seek  ␣ Play/Pause  C Change song  Q Exit",
				State.SelectSong: " ↑↓ Change selection  ↵ Select song  R Reload list  A Add song  ESC Cancel",
				State.AddSong: " ↵ Add song  ESC Cancel"
			];
		info = infos[state];
		putString(info, 0, h-1, Color.black, Color.white);

		flush();
		Event e;
		peekEvent(&e, 1);

		float voloffset = 0.02;
		if (state == State.AddSong)
		{
			if(e.key == Key.esc)
			{
				selectSong();
			}
			else if(e.key == Key.enter)
			{
				hideCursor();
				import xp.platforms;
				string uri = addsonginput;
				PlatformProvider prov = autoGetProviderForURI(uri);
				if(prov is null)
				{
					addsonginput = "";
					addsongError = "Unable to handle URI";
					continue;
				}

				SongInfo si = prov.getSongInfo(uri);
				
				int bw = 50;
				int bh = 7;
				int x = (w/2) - (bw/2);
				int y = (h/2) - (bh/2);
				putString(("Downloading \"" ~ si.author ~ " - " ~ si.title ~ "\"…").to!wstring, x + 1, y + 1);
				flush();

				string file = prov.downloadFile(uri);
				import xp.library : dbAddSong = addSong;
				dbAddSong(si, file);

				songs = getSongs();
				selectSong();
				continue;
			}
			else if(e.key == Key.backspace || e.key == Key.backspace2)
			{
				if(addsonginput.length)
				{
					import std.string;
					if(addsonginput.length == 1)
						addsonginput = "";
					else
						addsonginput = addsonginput[0..addsonginput.length - 2];
				}
			}
			else if(e.ch)
			{
				addsonginput ~= e.ch;
			}
		}
		else
		{
			if (e.key == Key.mouseLeft)
			{
				if (e.x == 0)
				{
					float vol = 1 - ((e.y) / (h - 1.0));
					setVolume(vol);
				}
				if (e.y == h - 2 && e.x >= 4 && e.x <= w - 2)
				{
					import std.math;

					float pos = ((e.x - 9.0) / (w - 16));
					pos = clamp(pos, 0, 1);
					seek(pos * getLength());
				}
				if (currentSong !is null && (e.x >= 1 && e.x <= 3) && e.y == h - 2)
				{
					togglePause();
				}

				int bh = currentSong is null ? h - 1 : h - 3;
				if (e.x > 2 && e.y > 0)
				{
					int click = -((e.y + 2) - bh);
					putString(click.to!wstring, 4, 4);
					if (click < songs.length && click > -1)
					{
						selection = click;
						if (currentSong != songs[selection])
						{
							selectCurrentSong();
							continue;
						}
					}
				}
			}
		}
		if (state == State.SelectSong)
		{
			if (e.key == Key.arrowUp || e.ch == '+' || e.key == Key.mouseWheelUp)
			{
				selection = clamp(selection + 1, 0, cast(int) songs.length - 1);
			}
			else if (e.key == Key.arrowDown || e.ch == '-' || e.key == Key.mouseWheelDown)
			{
				selection = clamp(selection - 1, 0, cast(int) songs.length - 1);
			}
			else if (e.key == Key.esc || e.ch == 'c')
			{
				state = State.Player;
			}
			else if (e.ch == 'r')
			{
				songs = getSongs();
			}
			else if (e.ch == 'a')
			{
				addSong();
			}
			else if (e.key == Key.enter || e.key == Key.space)
			{
				selectCurrentSong();
			}
		}
		else if (state == State.Player)
		{
			if (e.key == Key.arrowUp || e.ch == '+' || e.key == Key.mouseWheelUp)
			{
				setVolume(getVolume() + voloffset);
			}
			else if (e.key == Key.arrowDown || e.ch == '-' || e.key == Key.mouseWheelDown)
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
		}

		import xp.mpris;

		mprisPoll();
	}
}
