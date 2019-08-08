module proto.beta;

import proto.proto;
import net.connection;
import std.typecons;

class beta_protocol: protocol {
	private {
		import util.conv;
	}

	void init(string ver) {
	}

	void start_ping(string addr, ushort port, ref connection con) {
		import std.datetime.systime;
		import std.stdio;
		send_time = Clock.currStdTime(); 
		con.send_some([0xFE]);
	}

	protocol_data parse_packets(ref connection con) {
		import std.datetime.systime, std.algorithm, std.stdio;
		import std.array, std.conv;
		import util.text_formatter;

		ubyte[] resp = con.read_some();
		long recv_time = Clock.currStdTime(); 
		protocol_data data;


		assert(resp[0] == 0xFF);
		short len = decode_short(resp[1 .. 3].reverse);
		dstring str = decode_string_utf16be(resp[3 .. $], len);
		dstring[] strs = str.split('§');

		data.version_protocol = 0;
		data.version_name = "N/A";
		data.desc = to!string(strs[0]);
		data.players_online = to!int(strs[1]);
		data.players_max = to!int(strs[2]);
		data.ping_ms = (recv_time - send_time) / 10000;

		return data;
	}

	private {
		long send_time;
		string protocol_version;
	}
}
