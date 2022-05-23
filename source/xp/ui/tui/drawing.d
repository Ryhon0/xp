module xp.ui.tui.drawing;


void putString(wstring s, int x, int y, ushort fg = Color.white, ushort bg = Color.black)
{
	for (int i = 0; i < s.length; i++)
	{
		setCell(x + i, y, s[i], fg, bg);
	}
}

void putStringVertical(wstring s, int x, int y, ushort fg = Color.white, ushort bg = Color.black)
{
	for (int i = 0; i < s.length; i++)
	{
		setCell(x, y + i, s[i], fg, bg);
	}
}

static wchar[6] singleLineBoxChars = ['┌', '─', '┐', '│', '└', '┘'];
static wchar[6] roundBoxChars = ['╭', '─', '╮', '│', '╰', '╯'];
static wchar[6] dashedBoxChars = ['┌', '╶', '┐', '╷', '└', '┘'];
static wchar[6] doubleLineBoxChars = ['╔', '═', '╗', '║', '╚', '╝'];
void drawBox(int x, int y, int w, int h, wchar[6] chars, ushort color = Color.white)
{
	wstring charmul(wchar ch, int c)
	{
		wchar[] chars;
		chars.length = c;
		chars[] = ch;
		
		return chars.to!wstring;
	}

	putString([chars[0]], x, y, color);
	putString(charmul(chars[1], w - 1), x + 1, y, color);
	putString([chars[2]], x + w, y, color);

	putStringVertical(charmul(chars[3], h - 2), x, y + 1, color);
	putStringVertical(charmul(chars[3], h - 2), x + w, y + 1, color);

	putString([chars[4]], x, y + h - 1, color);
	putString(charmul(chars[1], w - 1), x + 1, y + h - 1, color);
	putString([chars[5]], x + w, y + h - 1, color);
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

float map(float value, float min1, float max1, float min2, float max2)
{
	return min2 + (value - min1) * (max2 - min2) / (max1 - min1);
}