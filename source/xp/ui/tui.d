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

void putString(wstring s, int x, int y, ushort fg = Color.white, ushort bg = Color.black)
{
	for (int i = 0; i < s.length; i++)
	{
		setCell(x + i, y, s[i], fg, bg);
	}
}

void tui()
{
	State state = State.SelectSong;

	init();
	scope (exit)
		shutdown();
	setInputMode(InputMode.esc | InputMode.mouse);

	void fullClear()
	{
		setClearAttributes(Color.white, Color.black);
		setClearAttributes(Color.black, Color.white);
		clear();
		flush();
	}

	SongInfo[] songs;
	int selection = 0;
	void selectSong()
	{
		songs = getSongs();
		selection = 0;
		state = State.SelectSong;
		fullClear();
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

	selectSong();
	setVolume(0.2);

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
						wstring text = (song.author ~ " - " ~ song.title).to!wstring;

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
					putString("No songs found, use 'xp add <uri>' to add them", 1, 1, Color.red, Color
							.black);
					putString("Press Q or ESC to exit", 1, 2, Color.red, Color.black);
				}

				Event e;
				peekEvent(&e, 1);
				flush();
				if (songs.length)
				{
					if (e.key == Key.mouseLeft)
					{
						int click = e.y - 1;
						if (click < 0 || click >= songs.length)
							continue;
						selection = click;

						selectCurrentSong();
					}
					else if (e.key == Key.arrowUp)
					{
						selection = clamp(selection - 1, 0, cast(int) songs.length - 1);
					}
					else if (e.key == Key.arrowDown)
					{
						selection = clamp(selection + 1, 0, cast(int) songs.length - 1);
					}
					else if (e.key == Key.enter)
					{
						selectCurrentSong();
					}
				}
				if (e.key == Key.esc || e.ch == 'q')
				{
					state = State.Player;
					write("\033[2J");
					clear();
				}

				break;
			}
		case State.Player:
		default:
			{
				setClearAttributes(Color.white, Color.black);
				clear();
				int w = width();
				int h = height();

				// Volume
				for (int i = 0; i < h - 2; i++)
				{
					bool filled;
					if (getVolume() == 0)
						filled = false;
					else
						filled = ((cast(float)((h - 3) - i) / (h - 3)) <= getVolume());

					setCell(0, i + 1, filled ? '█' : '░', filled ? Color.green
							: Color.white, Color.black);
				}

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

						barsize -= posstr.length - lenstr.length - 2;

						import std.algorithm;

						int barl = cast(int)(getPosition() / getLength() * barsize);
						if (barl == barsize)
							barl--;
						int barr = barsize - barl - 1;

						wstring stringmul(wstring s, int c)
						{
							wstring r = "";
							for (int i = 0; i < c; i++)
								r ~= s;
							return r;
						}

						int i = 4;
						putString(posstr, i, h - 2);
						i += posstr.length + 1;

						wstring bar;
						bool hqbar = true;
						if (hqbar)
						{
							bar = stringmul("█", barl);
							putString(bar, i, h - 2, Color.blue);
							i += bar.length;

							float map(float value, float min1, float max1, float min2, float max2)
							{
								return min2 + (value - min1) * (max2 - min2) / (max1 - min1);
							}

							double v = getPosition() / getLength();
							double startv = (i - 9) / cast(double) barsize;
							double nextv = (i - 8) / cast(double) barsize;
							wchar[] chars = ['▏', '▎', '▍', '▌', '▋', '▊', '▉','█'];
							wstring centerChar = [
								chars[cast(int) map(v, startv, nextv, 0, 7)]
							];
							putString(centerChar, i, h - 2, Color.blue);
							i += barr + 2;
						}
						else
						{
							bar = stringmul("═", barl);
							putString(bar, i, h - 2, Color.red);
							i += bar.length;

							putString("◯", i, h - 2, Color.blue);
							i++;

							bar = stringmul("─", barr);
							if (bar.length)
							{
								putString(bar, i, h - 2);
								i += bar.length;
							}
							i++;
						}

						putString(lenstr, i, h - 2);
					}

					wstring status = isFinished() ? "■" : (isPaused() ? "▌▌" : "▶");
					putString(status, 2, h - 2);

					// Song name
					wstring songname = (currentSong.author ~ " - " ~ currentSong.title).to!wstring;
					putString(songname, 2, h - 3, Color.white, Color.black);
				}

				// Bottom row info
				wstring info = "↑↓ Volume  ←→ Seek  ␣ Play/Pause  C Change song  Q Exit";
				putString(info, 0, h - 1, Color.black, Color.white);

				flush();
				Event e;
				peekEvent(&e, 1);

				float voloffset = 0.02;
				if (e.key == Key.mouseLeft)
				{
					if (e.x == 0)
					{
						float vol = 1 - ((e.y - 1.0) / (h - 2));
						setVolume(vol);
					}

					if (e.y == h - 2 && e.x >= 4 && e.x <= w - 2)
					{
						float pos = ((e.x - 9.0) / (w - 16));
						seek(pos * getLength());
					}
				}
				else if (e.key == Key.arrowUp || e.ch == '+' || e.key == Key.mouseWheelUp)
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

				break;
			}
		}

		import xp.mpris;

		mprisPoll();
	}
}
