module xp.ui.tui.scrollist;

import std.algorithm;
import std.math;
import termbox;

class ScrollList
{
	bool reversed = true;
	int itemcount = 0;
	int height = 0;

	int cursor = 0;
	int offset = 0;

	void handleEvent(Event ev)
	{
		if(itemcount == 0) return;

		if(ev.key == Key.arrowUp || ev.key == Key.mouseWheelUp)
		{
			if(reversed) cursor++;
			else cursor--;
		}
		else if(ev.key == Key.arrowDown || ev.key == Key.mouseWheelDown)
		{
			if(reversed) cursor--;
			else cursor++;
		}

		cursor = clamp(cursor, 0, itemcount-1);

		if(cursor - offset >= height)
			offset++;
		else if (cursor - offset < 0)
			offset--;
		
		if(ev.type == EventType.resize)
		{
			offset = max(0, itemcount - 1 - height);
		}
	}
}