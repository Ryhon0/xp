module xp.library;

import std.algorithm.iteration : map;
import std.array : join;
import xp.platforms;
import std.traits;
import d2sqlite3;
import std.stdio;

Database db;

struct DBVersion
{
	int ver = 0;
}

struct DBKey
{
}

void createOrUpdateDatabase(T)(string name, int currentVersion)
{
	import std.traits;

	T ti = new T();
	string getSQLType(T)()
	{
		static if (is(T == string))
			return "TEXT";
		else static if (is(T == int))
			return "INTEGER";
	}

	string[] sqls = ["CREATE TABLE IF NOT EXISTS " ~ name ~ "( "];
	int maxver = 0;
	static foreach (memname; __traits(derivedMembers, T))
	{
		static if (memname[0] != '_')
		{
			{
				alias m = __traits(getMember, ti, memname);
				alias mT = typeof(m);

				int ver = 0;
				alias vers = getUDAs!(m, DBVersion);
				static if (vers.length)
					ver = vers[0].ver;

				if (ver > maxver)
				{
					maxver = ver;
					sqls.length = maxver + 1;
				}

				if (ver == 0)
					sqls[0] ~= memname ~ " " ~ getSQLType!mT() ~ ", ";
				else
				{
					if (sqls[ver] == null)
						sqls[ver] = "";

					sqls[ver] ~= "ALTER TABLE " ~ name ~ " ADD " ~ memname ~ " " ~ getSQLType!mT() ~ ";";
				}
			}
		}
	}
	// Remove ','
	sqls[0] = sqls[0][0 .. $ - 2];
	sqls[0] ~= " )";

	import std.stdio;

	if (maxver > currentVersion)
		foreach (s; sqls[currentVersion .. $])
			db.execute(s);

	import std.conv;

	db.run("PRAGMA user_version = " ~ maxver.to!string);
}

void libraryInit()
{
	import standardpaths;
	import std.file;

	string datadir = writablePath(StandardPath.data, FolderFlag.create) ~ "/xp/";
	if (!exists(datadir))
		mkdir(datadir);

	db = Database(datadir ~ "xp.sqlite");

	int dbver = 0;
	db.run("PRAGMA user_version", (ResultRange rr) {
		dbver = rr.front()[0].as!int;
		return true;
	});

	createOrUpdateDatabase!SongInfo("songlist", dbver);
}

SongInfo[] getSongs()
{
	Statement st = db.prepare("SELECT * FROM songlist");
	ResultRange r = st.execute();
	SongInfo[] songs;

	foreach (rw; r)
	{
		SongInfo si = new SongInfo();

		alias mems = __traits(derivedMembers, SongInfo);
		static foreach (memname; mems)
		{
			static if (memname[0] != '_')
			{
				{
					alias T = typeof(__traits(getMember, si, memname));
					mixin("si." ~ memname ~ " = rw[memname].as!T;");
				}
			}
		}

		songs ~= si;
	}

	return songs;
}

bool isInLibrary(SongInfo song)
{
	Statement st = db.prepare(
		"SELECT id FROM songlist WHERE provider = :provider AND id = :id");
	string provider = song.provider, id = song.id;
	st.bindAll(provider, id);

	ResultRange r = st.execute();

	return !r.empty;
}

/// Removes song from database, DOES NOT REMOVE ASSOCIATED FILES
void removeSong(SongInfo si)
{
	db.execute("DELETE FROM songlist WHERE provider = :provider AND id = :id",
		si.provider, si.id);
}

void addSong(SongInfo si)
{
	string sql = "INSERT INTO songlist (";

	string[] ms;
	alias T = SongInfo;
	alias mems = __traits(derivedMembers, T);
	static foreach (memname; mems)
	{
		static if (memname[0] != '_')
		{
			ms ~= memname;
		}
	}

	sql ~= ms.join(",");
	sql ~= ") VALUES (";
	sql ~= ms.map!((string m) { return ":" ~ m; }).join(",");
	sql ~= ")";


	Statement st = db.prepare(sql);

	static foreach (memname; mems)
	{
		static if (memname[0] != '_')
		{
			// This took me 30 minutes to make it work
			// parameterIndex MUST include the :/@/$ part of the parameter
			// parameterName index argument starts at 1, so cool!
			st.bind(st.parameterIndex(":"~memname), mixin("si."~memname));
		}
	}

	st.execute();
}

void updateSong(SongInfo si)
{
	string sql = "UPDATE songlist SET ";

	string[] ms;
	alias T = SongInfo;
	alias mems = __traits(derivedMembers, T);
	static foreach (memname; mems)
	{
		static if (memname[0] != '_')
		{
			ms ~= memname;
		}
	}

	sql ~= ms.map!((string m) { return m ~ " = :" ~ m; }).join(", ");

	string[] keys;
	static foreach (memname; mems)
	{
		static if (memname[0] != '_')
		{
			{
				alias m = __traits(getMember, si, memname);
				static if (getUDAs!(m, DBKey).length)
				{
					keys ~= memname;
				}
			}
		}
	}
	sql ~= " WHERE ";
	sql ~= keys.map!((string k) { return k ~ " = :" ~ k; }).join(" AND ");
	sql ~= ";";

	Statement st;
	try
	{
		st = db.prepare(sql);
	}
	catch(Throwable t)
	{
		import termbox;
		shutdown();
		writeln(sql);
		writeln(t);
	}
	static foreach (memname; mems)
	{
		static if (memname[0] != '_')
		{
			st.bind(st.parameterIndex(":"~memname), mixin("si."~memname));
		}
	}

	st.execute();
}
