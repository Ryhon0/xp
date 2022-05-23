module xp.ui.tui.textentry;

import std.range.primitives;
import std.algorithm;
import std.traits;
import std.math;
import std.conv;
import termbox;

class TextEntry(T = dstring) if (isSomeString!T)
{
	alias TChar = ElementType!T;
	private T buf;
	this(T b = "")
	{
		buffer = b;
	}

	void buffer(T b) @property
	{
		buf = b;
		cursor = cast(int) b.length;
	}

	T buffer() @property const
	{
		return buf;
	}

	int cursor = 0;

	bool handleInput(Event e)
	{
		if (e.key == Key.backspace || e.key == Key.backspace2)
		{
			if (cursor == buf.length)
				buf = buf[0 .. $ - 1];
			else if (cursor != 0)
				buf = buf[0 .. cursor - 1] ~ buf[cursor .. $];

			cursor = max(cursor - 1, 0);
		}
		else if (e.key == Key.arrowLeft)
		{
			cursor = max(cursor - 1, 0);
		}
		else if (e.key == Key.arrowRight)
		{
			cursor = min(cursor + 1, buf.length);
		}
		else if (e.ch)
		{
			TChar ch = e.ch.to!TChar;

			if (cursor == buf.length)
				buf ~= ch;
			else if (cursor == 0)
				buf = ch ~ buf;
			else
				buf = buf[0 .. cursor] ~ ch ~ buf[cursor .. $];

			cursor++;
		}

		return true;
	}
}
