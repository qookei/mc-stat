module proto.latest;

import proto.proto;
import net.connection;
import std.typecons;

class latest_protocol: protocol {
	private {
		import util.conv;

		ubyte[] encode_packet(int type, ubyte[] payload) {
			ubyte[] tmp;
			ubyte[] type_enc = encode_var_int(type);
			int len = cast(int)payload.length + cast(int)type_enc.length;
			tmp ~= encode_var_int(len);
			tmp ~= type_enc;
			tmp ~= payload;

			return tmp;
		}

		auto decode_packet(ubyte[] data) {
			int type, len;
			int i = 0;

			auto dec = decode_var_int(data[i .. $]);
			len = dec.val;
			i += dec.len;

			dec = decode_var_int(data[i .. $]);
			type = dec.val;

			return tuple!("id", "len", "data")(type, i + len, data[i + dec.len .. i + len]);
		}

		ubyte[] encode_handshake(int protocol, string addr, ushort port) {
			ubyte[] tmp;
			tmp ~= encode_var_int(protocol);
			tmp ~= encode_string(addr);
			tmp ~= encode_short(port);
			tmp ~= encode_var_int(1); // State -> Status

			return encode_packet(0, tmp);
		}
	}

	void init(string ver) {
	}

	void start_ping(string addr, ushort port, ref connection con) {
		import std.datetime.systime;
		import std.stdio;
		con.send_some(encode_handshake(0, addr, port));
		con.send_some(encode_packet(0, [])); // Request packet, empty
		con.send_some(encode_packet(1, encode_long(Clock.currStdTime())));
	}

	protocol_data parse_packets(ref connection con) {
		ubyte[] resp = con.read_some();
		int off = 0;
		protocol_data data;

		while(off != -1 && off < resp.length) {
			off += parse_packet(resp[off .. $], data);
		}

		return data;
	}

	private {
		size_t parse_packet(ubyte[] data, ref protocol_data proto_data) {
			import std.datetime.systime;
			import std.stdio;
			import util.text_formatter;
			auto packet = decode_packet(data);
			switch (packet.id) {
				case 0x00: {
					import std.json, std.range, std.algorithm;
					JSONValue json = parseJSON(decode_string(packet.data).val);

					proto_data.version_name = json["version"]["name"].str;
					proto_data.version_protocol = json["version"]["protocol"].integer;

					proto_data.players_max = json["players"]["max"].integer;
					proto_data.players_online = json["players"]["online"].integer;
					try {
						json["players"]["sample"].array.each!(player =>
							proto_data.players_sample ~= player_info(
								player["name"].str,
								player["id"].str));
					} catch (JSONException e) {
						proto_data.players_sample = [];
					}

					proto_data.desc = format_json_text(json["description"]);
					if (proto_data.desc.length > 0)
						proto_data.desc ~= '\n';

					try {
						json["description"]["extra"].array.each!(desc =>
							proto_data.desc ~= format_json_text(desc));
					} catch (JSONException e) {
					}

					proto_data.desc = format_old_text(proto_data.desc);

					proto_data.favicon = [];

					try {
						string favicon = json["favicon"].str;
						if (favicon.startsWith("data:image/png;base64,")) {
							proto_data.favicon = decode_base64(favicon[22 .. $]);
						}
					} catch (JSONException e) {
					}

					break;
				}
				case 0x01: {
					auto send_time = decode_long(packet.data);
					proto_data.ping_ms = (Clock.currStdTime() - send_time) / 10000;
					break;
				}
				default: {
					writeln("invalid packet");
				}
			}
			return packet.len;
		}
	}
}
