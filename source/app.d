
import net.connection;
import proto.proto;
import proto.latest;
import proto.before_netty;
import proto.beta;

// This is a separate function to avoid conflicts
// between std.file and std.stdio.
void write_favicon(string name, ubyte[] data) {
	import std.file;
	name.write(data);
}

enum protocol_type {latest, beta, before_netty};

void main(string[] args) {
	import std.stdio;
	import std.socket;
	import std.getopt;

	ushort port = 25565;
	string addr;
	string favicon_path;
	protocol_type proto_type;
	string protocol_version;

	if (args.length < 2) {
		writeln("use --help/-h to see usage");
		return;
	}

	auto help_info = getopt(
		args,
		"address",	"Server address", &addr,
		"port",		"Server port (default: 25565)", &port,
		"favicon",	"Where to save favicon (empty to not save)", &favicon_path,
		"protocol",	"Which protocol to use (default: latest)", &proto_type,
		"version",	"Game version (only needed for the before_netty protocol)", &protocol_version,
	);

	if (help_info.helpWanted) {
		defaultGetoptPrinter("Minecraft server status getter", help_info.options);
		writeln("Available protocols: latest(1.7 and up), before_netty(1.4 to 1.6), beta(beta 1.8 to 1.3).");
		writefln("Example usage: %s --address 2b2t.org --favicon icon.png", args[0]);
		writeln();
		return;
	}

	connection con = new socket_connection();

	try {
		con.connect(addr, port);
	} catch (SocketException e) {
		writefln("Failed to connect: %s", e.msg);
		return;
	}

	scope(exit) con.disconnect();

	protocol proto;
	switch(proto_type) {
		case protocol_type.latest:
			proto = new latest_protocol();
			break;
		case protocol_type.before_netty:
			proto = new before_netty_protocol();
			break;
		case protocol_type.beta:
			proto = new beta_protocol();
			break;
		default:
			writeln("Invalid protocol... what?");
			return;
	}

	proto.init("");
	proto.start_ping(addr, port, con);
	auto data = proto.parse_packets(con);

	writeln("Server information:");

	writefln("Version: %s (protocol: %s)",
		data.version_name, data.version_protocol);

	writefln("Players: %s/%s", data.players_online, data.players_max);

	writefln("Ping to server: %s ms", data.ping_ms);

	if (data.players_sample.length) {
		writeln("Sample:");
		foreach (p; data.players_sample)
			writefln("\t%s (id: %s)", p.name, p.id);
	}

	writeln("\n" ~ data.desc);

	if (favicon_path.length)
		write_favicon(favicon_path, data.favicon);
}
