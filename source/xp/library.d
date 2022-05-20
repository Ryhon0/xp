module xp.library;

import xp.platforms;
import d2sqlite3;

Database db;

void libraryInit()
{
	db = Database("xp.sqlite");
	db.run("CREATE TABLE IF NOT EXISTS songlist (
	title	TEXT,
	author	TEXT,
	uri	TEXT,
	id	TEXT,
	provider	TEXT,
	file	TEXT
	);");
}

SongInfo[] getSongs()
{
	Statement st = db.prepare("SELECT * FROM songlist");
	ResultRange r = st.execute();
	SongInfo[] songs;

	foreach (rw; r)
	{
		SongInfo si = new SongInfo();
		si.title = rw["title"].as!string;
		si.author = rw["author"].as!string;
		si.id = rw["id"].as!string;
		si.uri = rw["uri"].as!string;
		si.provider = rw["provider"].as!string;
		songs ~= si;
	}

	return songs;
}

SongInfo getSongById(string provider, string id)
{
	Statement st = db.prepare(
		"SELECT * FROM songlist WHERE provider = :provider AND id = :id LIMIT 1");
	st.bindAll(provider, id);

	ResultRange r = st.execute();

	if (r.empty)
		return null;

	SongInfo si = new SongInfo();

	Row rw = r.front();
	si.title = rw["title"].as!string;
	si.author = rw["author"].as!string;
	si.id = rw["id"].as!string;
	si.uri = rw["uri"].as!string;
	si.provider = rw["provider"].as!string;

	return si;
}

string getSongFile(SongInfo song)
{
	Statement st = db.prepare(
		"SELECT * FROM songlist WHERE provider = :provider AND id = :id LIMIT 1");
	string provider = song.provider, id = song.id;
	st.bindAll(provider, id);

	ResultRange r = st.execute();

	if (r.empty)
		return null;

	SongInfo si = new SongInfo();

	Row rw = r.front();
	return rw["file"].as!string;
}

void addSong(SongInfo si, string file)
{
	Statement st = db.prepare(
		"INSERT INTO songlist (title,author,uri,id,provider,file) VALUES (:title,:author,:uri,:id,:provider,:file)");
	
	string title = si.title, author = si.author, uri = si.uri, id = si.id, provider = si.provider;
	st.bindAll(title, author, uri, id, provider, file);
	st.execute();
}
