module proto.proto;

import net.connection;

interface protocol {
	void init(string ver);
	void start_ping(string addr, ushort port, ref connection con);
	protocol_data parse_packets(ref connection con);
}

struct player_info {
	string name;
	string id;
}

struct protocol_data {
	string version_name;
	long version_protocol;

	long players_online;
	long players_max;
	player_info[] players_sample;

	string desc; // formatted with ansi codes

	ubyte[] favicon; // raw binary data to write to file

	long ping_ms;
}
