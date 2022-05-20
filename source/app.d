import yajl : encode;
import arsd.terminal;
import bindbc.sdl;
import std.stdio;
import std.conv;
import std.json;

int main(string[] args)
{
	import xp.player;
	playerInit();

	import xp.mpris;
	registerMpris();

	import xp.ui.gtk.mainwindow;
	import gio.Application : GioApplication = Application;
	import gtk.Application;

	auto application = new Application("link.ryhn.xp", GApplicationFlags.FLAGS_NONE);
	application.addOnActivate(delegate void(GioApplication app) {
		auto win = new MainWindow(application);
		win.show();
	});
	return application.run([]);
}