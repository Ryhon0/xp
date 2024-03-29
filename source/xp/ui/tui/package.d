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
	AddSong,
	EditSong
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

	import xp.ui.tui.scrollist;
	ScrollList songScrollList = new ScrollList();
	SongInfo[] songs;
	void selectSong()
	{
		state = State.SelectSong;
	}

	import xp.ui.tui.textentry;
	TextEntry!dstring addSongInput;

	dstring addSongError;
	void addSong()
	{
		state = State.AddSong;
		addSongInput = new TextEntry!dstring();
		addSongError = "";
	}

	TextEntry!dstring editSongTitle;
	TextEntry!dstring editSongAuthor;
	int editSongField;
	void editSong()
	{
		editSongField = 0;
		SongInfo song = songs[songScrollList.cursor];
		editSongTitle = new TextEntry!dstring(song.title.to!dstring);
		editSongAuthor = new TextEntry!dstring(song.author.to!dstring);
		state = State.EditSong;
	}

	SongInfo currentSong;
	void selectCurrentSong()
	{
		SongInfo song = songs[songScrollList.cursor];
		currentSong = song;
		string file = song.file;
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
		{
			import std.algorithm.mutation;

			wchar[] volchars = verticalSmoothProgressChars.dup;
			wstring volbar = progressBar(1 - getVolume(), h - 1, volchars.reverse());
			putStringVertical(volbar, 0, 0, Color.green | Attribute.bright, Color.white);
		}

		// Song controls
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

				putString(lenstr, i, h - 2);
			}

			// Status
			wstring status = isFinished() ? "■" : (isPaused() ? "▌▌" : "▶");
			putString(status, 2, h - 2);

			// Song name
			wstring songname = (currentSong.author ~ " - " ~ currentSong.title).to!wstring;
			putString(songname, 2, h - 3, Color.white, Color.black);
		}

		// Song list
		{
			int bh = currentSong is null ? h - 1 : h - 3;

			songScrollList.height = bh - 2;
			songScrollList.itemcount = cast(int)songs.length;

			clearBox(2, 0, w - 3, bh);
			if (songs.length)
			{
				for (int i = 0; i < bh - 1; i++)
				{
					int id = i + songScrollList.offset;
					if (id >= songs.length)
						break;

					int y = bh - 2 - i;
					int x = 3;
					SongInfo song = songs[id];
					ushort col = id % 2 == 0 ? Color.white : Color.black | Attribute.bright;
					ushort bg = Color.black;

					if (songScrollList.cursor == id)
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
				putString("Use 'xp add <uri>' or press A to add songs", 3, bh - 2, Color.red, Color
						.black);
			}
			ushort bcol = state == State.SelectSong ? Color.white : Color.black | Attribute.bright;
			drawBox(2, 0, w - 3, bh, roundBoxChars, bcol);

			// Scroll bar
			if(songScrollList.height < songs.length)
			{
				float scrollv = (songScrollList.cursor / cast(float)songs.length);
				scrollv = -(0 - scrollv);
				putStringVertical(progressBar(scrollv, bh-2, ['║','◯','║']), w-1, 1, bcol);
				putString("Song list", 4, 0, bcol);
			}

			import xp;

			wstring verstr = ("xp " ~ xpVersion).to!wstring;
			putString(verstr, cast(int)(w - verstr.length - 2), bh - 1, bcol);
		}

		// Add song window
		if (state == State.AddSong)
		{
			int bw = 50;
			int bh = 5;
			int x = (w / 2) - (bw / 2);
			int y = (h / 2) - (bh / 2);

			drawBox(x, y, bw, bh, singleLineBoxChars);
			clearBox(x + 1, y + 1, bw - 2, bh - 2);
			putString("Add song", x + 1, y);
			putString("URI:", x + 1, y + 1);
			putString(addSongError, x + 1, y + 3, Color.red);

			auto ws = addSongInput.buffer;
			putString(ws, x + 1, y + 2, Color.white, Color.black | Attribute.bright);
			putString(charmul(' ', cast(int)(bw - ws.length - 1)), cast(int)(x + 1 + ws.length), y + 2,
				Color.white, Color.black | Attribute.bright);
			setCursor(cast(int)(x + 1 + addSongInput.cursor), y + 2);
		}

		// Edit song window
		if (state == State.EditSong)
		{
			int bw = 50;
			int bh = 6;
			int x = (w / 2) - (bw / 2);
			int y = (h / 2) - (bh / 2);

			drawBox(x, y, bw, bh, singleLineBoxChars);
			clearBox(x + 1, y + 1, bw - 2, bh - 2);

			putString("Edit song", x + 1, y);
			putString("Author:", x + 1, y + 1);
			putString("Title:", x + 1, y + 3);

			auto ws = editSongAuthor.buffer;
			putString(ws, x + 1, y + 2, Color.white, Color.black | Attribute.bright);
			putString(charmul(' ', cast(int)(bw - ws.length - 1)), cast(int)(x + 1 + ws.length), y + 2,
				Color.white, Color.black | Attribute.bright);
			if (editSongField == 0)
				setCursor(cast(int)(x + 1 + editSongAuthor.cursor), y + 2);

			ws = editSongTitle.buffer;
			putString(ws, x + 1, y + 4, Color.white, Color.black | Attribute.bright);
			putString(charmul(' ', cast(int)(bw - ws.length - 1)), cast(int)(x + 1 + ws.length), y + 4,
				Color.white, Color.black | Attribute.bright);
			if (editSongField == 1)
				setCursor(cast(int)(x + 1 + editSongTitle.cursor), y + 4);
		}

		// Bottom row info
		{
			wstring info;
			wstring[State] infos =
				[
					State.Player: " ↑↓ Volume  ←→ Seek  ␣ Play/Pause  C Change song  Q Exit",
					State.SelectSong: " ↑↓ Select  ↵ Play  R Reload  A Add song  E Edit  ESC Cancel",
					State.AddSong: " ↵ Add song  ESC Cancel",
					State.EditSong: " ↑↓ Select field  ↵ Save  ESC Cancel"
				];
			info = infos[state];
			putString(info, 0, h - 1, Color.black, Color.white);
		}

		flush();
		Event e;
		peekEvent(&e, 1);

		// Input
		float voloffset = 0.02;
		if (state == State.AddSong)
		{
			if (e.key == Key.esc)
			{
				hideCursor();
				selectSong();
				addSongInput = null;
				addSongError = "";
				continue;
			}
			else if (e.key == Key.enter)
			{
				hideCursor();
				import xp.platforms;

				string uri = addSongInput.buffer.to!string;
				PlatformProvider prov = autoGetProviderForURI(uri);
				if (prov is null)
				{
					addSongInput.buffer = "";
					addSongError = "Unable to handle URI";
					continue;
				}

				SongInfo si = prov.getSongInfo(uri);

				// Check if already in library
				if(isInLibrary(si))
				{
					addSongError = "Song already in library";
					foreach(i,s; songs)
						if(s.id == si.id && s.provider == si.provider)
						{
							songScrollList.cursor = cast(int)i;
							break;
						}

					continue;
				}

				int bw = 50;
				int bh = 7;
				int x = (w / 2) - (bw / 2);
				int y = (h / 2) - (bh / 2);
				putString(("Downloading \"" ~ si.author ~ " - " ~ si.title ~ "\"…")
						.to!wstring, x + 1, y + 4);
				flush();

				si.file = prov.downloadFile(si);
				import xp.library : dbAddSong = addSong;

				dbAddSong(si);
				songs = getSongs();

				foreach(i,s; songs)
					if(s.id == si.id && s.provider == si.provider)
					{
						songScrollList.cursor = cast(int)i;
						break;
					}

				selectSong();
				addSongInput = null;
				addSongError = "";
				continue;
			}
			else addSongInput.handleInput(e);
		}
		else if (state == State.EditSong)
		{
			if (e.key == Key.esc)
			{
				hideCursor();
				selectSong();
				editSongAuthor = editSongTitle = null;
				continue;
			}
			else if (e.key == Key.enter)
			{
				hideCursor();

				SongInfo si = songs[songScrollList.cursor];
				si.author = editSongAuthor.buffer.to!string;
				si.title = editSongTitle.buffer.to!string;

				updateSong(si);

				songs = getSongs();
				selectSong();
				editSongAuthor = editSongTitle = null;
				continue;
			}
			else if (e.key == Key.arrowUp)
			{
				import std.math;
				editSongField = abs((editSongField - 1)) % 2;
			}
			else if (e.key == Key.arrowDown || e.key == Key.tab)
			{
				editSongField = (editSongField + 1) % 2;
			}
			else 
			{
				(editSongField == 0 ? editSongAuthor : editSongTitle).handleInput(e);
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
					click += songScrollList.offset;
					if (click < songs.length && click > -1)
					{
						songScrollList.cursor = click;
						if (currentSong != songs[songScrollList.cursor])
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
			songScrollList.handleEvent(e);

			if (e.key == Key.esc || e.ch == 'c')
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
			else if (e.key == Key.f2 || e.ch == 'e')
			{
				editSong();
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
