module xp.player;

import bindbc.sdl;

__gshared
{
	int sl = 0;
	Mix_Music* mus;
	bool finished = false;
}
extern (C) nothrow
{
	void lenmix(void* udata, ubyte* stream, int len)
	{
		if (!Mix_PausedMusic())
		{
			sl += len;
		}
	}

	void musicfinished()
	{
		sl = 0;
		finished = true;
		Mix_PlayMusic(mus, 0);
		Mix_PauseMusic();
	}
}

int lengthSecs = 0;

void playerInit()
{
	loadSDL();
	loadSDLMixer();

	SDL_Init(SDL_INIT_AUDIO);
	Mix_Init(Mix_InitFlags.max);
	Mix_OpenAudio(44_100, MIX_DEFAULT_FORMAT, 2, 1024);

	int adevc = SDL_GetNumAudioDevices(0);
	//writeln("Available outputs");
	for (int i = 0; i < adevc; i++)
	{
		import std.conv;
		//writeln(SDL_GetAudioDeviceName(i, 0).to!string);
	}
	int dev = Mix_OpenAudioDevice(44_100, MIX_DEFAULT_FORMAT, 2, 1024, SDL_GetAudioDeviceName(0, 0), 1);

	Mix_SetPostMix(&lenmix, null);
	Mix_HookMusicFinished(&musicfinished);
}

void playFile(const char* path)
{
	import tag;

	const TagLib_File* f = taglib_file_new(path);
	const(TagLib_AudioProperties*) props = taglib_file_audioproperties(f);

	lengthSecs = taglib_audioproperties_length(props);

	mus = Mix_LoadMUS(path);
	Mix_PlayMusic(mus, 0);
	pause();
	sl = 0;
}

bool isFinished()
{
	return finished;
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

void togglePause()
{
	if (isPaused)
		resume();
	else
		pause();
}

double samplesToSecs(int samples)
{
	return samples / 44_100.0 / 4;
}

int secsToSamples(double secs)
{
	return cast(int)(secs * 44_100 * 4);
}

double getLength()
{
	return lengthSecs;
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
