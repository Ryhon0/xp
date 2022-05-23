module xp.ui.tui.drawing;

import std.algorithm;
import std.traits;
import std.conv;
import termbox;

void putString(T)(T s, int x, int y, ushort fg = Color.white, ushort bg = Color.black)
		if (isSomeString!T)
{
	for (int i = 0; i < s.length; i++)
	{
		setCell(x + i, y, s[i], fg, bg);
	}
}

void putStringVertical(T)(T s, int x, int y, ushort fg = Color.white, ushort bg = Color.black)
		if (isSomeString!T)
{
	for (int i = 0; i < s.length; i++)
	{
		setCell(x, y + i, s[i], fg, bg);
	}
}

immutable(T[]) charmul(T)(T ch, int c)
	if(isSomeChar!T)
{
	T[] chars;
	chars.length = c;
	chars[] = ch;

	return cast(immutable(T[]))chars;
}

static const
{
	wchar[6] singleLineBoxChars = ['┌', '─', '┐', '│', '└', '┘'];
	wchar[6] roundBoxChars = ['╭', '─', '╮', '│', '╰', '╯'];
	wchar[6] dashedBoxChars = ['┌', '╶', '┐', '╷', '└', '┘'];
	wchar[6] doubleLineBoxChars = ['╔', '═', '╗', '║', '╚', '╝'];
	wchar[6] fallbackBoxChars = ['+', '-', '+', '|', '+', '+'];
}

void drawBox(int x, int y, int w, int h, wchar[6] chars, ushort color = Color.white)
{
	putString([chars[0]], x, y, color);
	putString(charmul(chars[1], w - 1), x + 1, y, color);
	putString([chars[2]], x + w, y, color);

	putStringVertical(charmul(chars[3], h - 2), x, y + 1, color);
	putStringVertical(charmul(chars[3], h - 2), x + w, y + 1, color);

	putString([chars[4]], x, y + h - 1, color);
	putString(charmul(chars[1], w - 1), x + 1, y + h - 1, color);
	putString([chars[5]], x + w, y + h - 1, color);
}

void clearBox(int x, int y, int w, int h)
{
	string str = charmul(' ', w);

	for(int i = 0; i<h; i++)
	{
		putString(str, x,y+i);
	}
}

static wchar[] horizontalSmoothProgressChars = [
	' ', '▏', '▎', '▍', '▌', '▋', '▊', '▉', '█'
];
static wchar[] verticalSmoothProgressChars = [
	' ', '▁', '▂', '▃', '▄', '▅', '▆', '▇', '█'
];
wstring progressBar(float value, int length, wchar[] chars = horizontalSmoothProgressChars)
{
	wstring s = "";
	for (int i = 0; i < length; i++)
	{
		float minv = i / cast(float) length;
		float maxv = (i + 1) / cast(float) length;

		if (value >= minv)
		{
			if (value >= maxv)
				s ~= chars[chars.length - 1];
			else
				s ~= chars[min(cast(int) map(value, minv, maxv, 1, chars.length - 1), chars.length - 1)];
		}
		else
		{
			s ~= chars[0];
		}
	}
	return s;
}

float map(T)(T value, T min1, T max1, T min2, T max2) if (isFloatingPoint!T)
{
	return min2 + (value - min1) * (max2 - min2) / (max1 - min1);
}
