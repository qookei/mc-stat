module proto.before_netty;

import proto.proto;
import net.connection;
import std.typecons;

class before_netty_protocol: protocol {
	private {
		import util.conv;

		ubyte[] encode_ping_req(int protocol, string addr, ushort port) {
			import std.algorithm;
			ubyte[] tmp;
			tmp ~= 0xFE; // packet ident
			tmp ~= 0x01; // packet payload
			if (protocol_version == "1.6") {
				tmp ~= 0xFA; // plugin ident
				tmp ~= [0x00, 0x0B]; // length of following str
				tmp ~= encode_string_utf16be("MC|PingHost");
				auto enc_host = encode_string_utf16be(addr); 
				tmp ~= encode_short(cast(short)(7 + enc_host.length)).reverse;
				tmp ~= protocol & 0xFF;
				tmp ~= encode_short(cast(short)addr.length).reverse;
				tmp ~= enc_host;
				tmp ~= encode_int(port).reverse;
			}
			return tmp;
		}
	}

	void init(string ver) {
		protocol_version = ver;
	}

	void start_ping(string addr, ushort port, ref connection con) {
		import std.datetime.systime;
		import std.stdio;
		send_time = Clock.currStdTime(); 
		con.send_some(encode_ping_req(74, addr, port));
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
		dstring[] strs = str.split('\0');

		assert(strs[0] == "§1"d);
		data.version_protocol = to!int(strs[1]);
		data.version_name = to!string(strs[2]);
		data.desc = format_old_text(to!string(strs[3]));
		data.players_online = to!int(strs[4]);
		data.players_max = to!int(strs[5]);
		data.ping_ms = (recv_time - send_time) / 10000;

		return data;
	}

	private {
		long send_time;
		string protocol_version;
	}
}
