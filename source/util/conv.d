module util.conv;

import std.typecons;

class invalid_conversion_exception : Exception {
    this(string msg, string file = __FILE__, size_t line = __LINE__) {
        super(msg, file, line);
    }
}

ubyte[] decode_base64(string str) {
	import std.base64;
	return Base64.decode(str);
}

ubyte[] encode_var_int(int val) {
	ubyte[] tmp;
	do {
		ubyte b = val & 0x7F;
		val >>= 7;
		if (val)
			b |= 0x80;
		tmp ~= b;
	} while(val);

	return tmp;
}

auto decode_var_int(ubyte[] data) {
	int val;
	ubyte tmp;
	size_t i;
	do {
		tmp = data[i];
		val |= (tmp & 0x7F) << (7 * i);
		i++;
		if (i > 5)
			throw new invalid_conversion_exception("var int too long");
	} while(tmp & 0x80);

	return tuple!("val", "len")(val, i);
}

ubyte[] encode_string(string str) {
	ubyte[] tmp;
	tmp ~= encode_var_int(cast(int)str.length);
	tmp ~= str[0 .. $];
	return tmp;
}

auto decode_string(ubyte[] data) {
	import std.conv, std.encoding;

	auto dec_len = decode_var_int(data);

	ubyte[] tmp = data[dec_len.len .. $];

	dstring dstr;
	for (size_t i = 0; i < dec_len.val && tmp.length; i++) {
		dstr ~= safeDecode(tmp);
	}

	string str = to!string(dstr);

	return tuple!("val", "len")(
		str,
		dec_len.val + str.length
	);
}

ubyte[] encode_string_utf16be(string str) {
	import std.encoding, std.range, std.algorithm;
	auto e = EncodingScheme.create("utf-16le");
	ubyte[] tmp;

	foreach(c; str) {
		ubyte[16] buf;
		auto l = e.encode(c, buf);
		tmp ~= buf[0 .. l];
	}

	return tmp.chunks(2).map!(chunk => chunk.array.reverse).join;
}

auto decode_string_utf16be(ubyte[] data, size_t length) {
	import std.conv, std.encoding, std.range, std.algorithm;

	auto e = EncodingScheme.create("utf-16le");

	const(ubyte)[] tmp = data.chunks(2).map!(chunk => chunk.array.reverse).join;

	dstring dstr;
	for (size_t i = 0; i < length && data.length; i++) {
		dstr ~= e.safeDecode(tmp);
	}

	return dstr;
}

ubyte[] encode_short(ushort v) {
	ubyte[] tmp;
	tmp ~= v & 0xFF;
	tmp ~= (v >> 8) & 0xFF;
	return tmp;
}

ushort decode_short(ubyte[] data) {
	return data[0] | (data[1] << 8);
}

ubyte[] encode_long(ulong v) {
	ubyte[] tmp;
	for (size_t i = 0; i < 8; i++) {
		tmp ~= v & 0xFF;
		v >>= 8;
	}
	return tmp;
}

ulong decode_long(ubyte[] data) {
	ulong tmp = 0;
	for (size_t i = 0; i < 8; i++) {
		tmp |= (cast(ulong)(data[i]) << (i * 8));
	}

	return tmp;
}

ubyte[] encode_int(uint v) {
	ubyte[] tmp;
	for (size_t i = 0; i < 4; i++) {
		tmp ~= v & 0xFF;
		v >>= 8;
	}
	return tmp;
}

uint decode_int(ubyte[] data) {
	uint tmp = 0;
	for (size_t i = 0; i < 4; i++) {
		tmp |= (cast(uint)(data[i]) << (i * 8));
	}

	return tmp;
}
