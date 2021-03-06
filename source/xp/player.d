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
		if (!finished && !Mix_PausedMusic())
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

	TagLib_File* f = taglib_file_new(path);
	const(TagLib_AudioProperties*) props = taglib_file_audioproperties(f);

	lengthSecs = taglib_audioproperties_length(props);

	taglib_file_free(f);
	if(mus) Mix_FreeMusic(mus);

	mus = Mix_LoadMUS(path);
	Mix_PlayMusic(mus, 0);
	pause();
	finished = false;
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
	finished = false;
	seek(getPosition());
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

import std.algorithm;

void seek(double secs)
{
	sl = clamp(secsToSamples(secs), 0, secsToSamples(getLength()));
	Mix_SetMusicPosition(secs);
}

float getVolume()
{
	return clamp(Mix_VolumeMusic(-1) / 128.0, 0, 1);
}

void setVolume(float vol)
{
	vol = clamp(vol, 0, 1);
	Mix_VolumeMusic(cast(int)(vol * 128));
}
