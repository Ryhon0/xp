import yajl : encode;
import arsd.terminal;
import bindbc.sdl;
import std.stdio;
import std.conv;
import std.json;

__gshared int sl = 0;
__gshared Mix_Music* mus;
extern (C) nothrow void lenmix(void* udata, ubyte* stream, int len)
{
	if (!Mix_PausedMusic())
	{
		sl += len;
		printf("\u001b[0G");
		printf("\u001b[1A");
		printf("\u001b[K");
		printf("%f   ", sl / 44100.0 / 4);
		printf("\u001b[1B");
		printf("\u001b[0G");
		fflush(core.stdc.stdio.stdout);
	}
}

extern (C) nothrow void musicfinished()
{
	sl = 0;
	printf("music finished\n");
	Mix_PlayMusic(mus, 0);
	Mix_PauseMusic();
}

int main(string[] args)
{
	/*
	import xp.platforms.soundcloud;
	import xp.platforms.localfile;
	import xp.platforms.youtube;
	import xp.platforms.spotify;
	import xp.platforms;

	if (args.length < 2)
	{
		writeln("Ussage: " ~ args[0] ~ " <song uri>");
		return 0;
	}

	string uri = args[1];

	PlatformProvider[] ps;
	ps ~= new SoundCloudPlatform();
	ps ~= new LocalfilePlatform();
	ps ~= new YoutubePlatform();
	ps ~= new SpotifyPlatform();

	PlatformProvider p;
	foreach (cp; ps)
	{
		if (cp.canHandle(uri))
		{
			p = cp;
			break;
		}
	}

	if (p is null)
	{
		writeln("Cannot handle uri " ~ uri);
		return 1;
	}

	writeln("Handling uri using " ~ p.classinfo.to!string);
	writeln(encode(p.getSongInfo(uri)));
	string dluri = p.getDownload(uri);

	import std.net.curl;
	import std.process;
	*/
	/*
	auto dl = executeShell("xdg-open '" ~ dluri ~ "'");
	if(dl.status != 0)
	{
		writeln(dl.output);
		return 1;	
	}
	*/

	loadSDL();
	loadSDLMixer();

	SDL_Init(SDL_INIT_AUDIO);

	Mix_OpenAudio(44_100, MIX_DEFAULT_FORMAT, 2, 1024);
	printf(SDL_GetError());
	mus = Mix_LoadMUS("music");

	Mix_PlayMusic(mus, 0);

	Mix_SetPostMix(&lenmix, null);
	Mix_HookMusicFinished(&musicfinished);

	import mainwindow;
	import gio.Application : GioApplication = Application;
	import gtk.Application;

	auto application = new Application("link.ryhn.xp", GApplicationFlags.FLAGS_NONE);
	application.addOnActivate(delegate void(GioApplication app) {
		auto win = new MainWindow(application);
		win.show();
	});
	return application.run([]);

	/*
	while (true)
	{
		//break;
		auto terminal = Terminal(ConsoleOutputType.linear);
		auto input = RealTimeConsoleInput(&terminal, ConsoleInputFlags.raw);

		auto c = input.getch();

		if (c == 'q')
			break;

		if (c == '+')
		{
			float vol = getVolume() + 0.1;
			writeline("🔊" ~ vol.to!string);
			setVolume(vol);
		}

		if (c == '-')
		{
			float vol = getVolume() - 0.1;
			writeline("🔊" ~ vol.to!string);
			setVolume(vol);
		}

		if (c == 'p')
		{
			if (!isPaused())
			{
				pause();
				writeline("■");
			}
			else
			{
				resume();
				writeline("▶");
			}
		}

		import std.algorithm;

		if (c == 'd')
		{
			seek(getPosition() + 1);
			writeline(">>" ~ getPosition().to!string);
		}
		if (c == 'a')
		{
			seek(getPosition() - 1);
			writeline("<<" ~ getPosition().to!string);
		}

		if (c == 'r')
		{
			seek(0);
		}
	}

	Mix_FreeMusic(mus);
	Mix_CloseAudio();
	return 0;
	*/
}

bool isPaused()
{
	return Mix_PausedMusic() != 0;
}

void pause()
{
	Mix_PauseMusic();
}

void resume()
{
	Mix_ResumeMusic();
}

double samplesToSecs(int samples)
{
	return samples / 44_100.0 / 4;
}

int secsToSamples(double secs)
{
	return cast(int)(secs * 44_100 * 4);
}

double getPosition()
{
	return samplesToSecs(sl);
}

void setPosition(double secs)
{
	sl = secsToSamples(secs);
}

void seek(double secs)
{
	setPosition(secs);
	Mix_SetMusicPosition(secs);
}

import std.algorithm;

float getVolume()
{
	return clamp(Mix_VolumeMusic(-1) / 128.0, 0, 1);
}

void setVolume(float vol)
{
	vol = clamp(vol, 0, 1);
	Mix_VolumeMusic(cast(int)(vol * 128));
}

void writeline(string s)
{
	write("\u001b[K");
	write(s);
}
