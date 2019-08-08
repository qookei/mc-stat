module util.text_formatter;

import std.json;

auto read_property(E)(JSONValue val, string s, E def) {
	import std.conv;
	try {
		return to!E(val[s].str);
	} catch (JSONException e) {
		return def;
	}
}

string format_json_text(JSONValue val) {
	string str;
	if (read_property(val, "italic", false)) str ~= "\x1b[3m";
	if (read_property(val, "bold", false)) str ~= "\x1b[1m";
	if (read_property(val, "strikethrough", false)) str ~= "\x1b[9m";
	if (read_property(val, "underline", false)) str ~= "\x1b[4m";
	str ~= "\x1b[22m";
	switch(read_property(val, "color", "")) {
		case "black": str ~= "\x1b[30m"; break;
		case "dark_blue": str ~= "\x1b[34m"; break;
		case "dark_green": str ~= "\x1b[32m"; break;
		case "dark_aqua": str ~= "\x1b[36m"; break;
		case "dark_red": str ~= "\x1b[31m"; break;
		case "dark_purple": str ~= "\x1b[35m"; break;
		case "gold": str ~= "\x1b[33m"; break;
		case "gray": str ~= "\x1b[37m"; break;
		case "dark_gray": str ~= "\x1b[90m"; break;
		case "blue": str ~= "\x1b[94m"; break;
		case "green": str ~= "\x1b[92m"; break;
		case "aqua": str ~= "\x1b[96m"; break;
		case "red": str ~= "\x1b[91m"; break;
		case "light_yellow": str ~= "\x1b[95m"; break;
		case "yellow": str ~= "\x1b[93m"; break;
		case "white": str ~= "\x1b[97m"; break;
		default: break;
	}
	str ~= val["text"].str;
	str ~= "\x1b[0m";
	return str;
}

string format_old_text(string val) {
	import std.conv;
	string str;
	dstring tmp = to!dstring(val);
	bool code_next;

	foreach (i, c; tmp) {
		if (code_next) {
			code_next = false;
			switch(c) {
				case 'l': str ~= "\x1b[1m\x1b[22m"; break;
				case 'm': str ~= "\x1b[9m"; break;
				case 'o': str ~= "\x1b[3m"; break;
				case 'n': str ~= "\x1b[4m"; break;
				case 'r': str ~= "\x1b[0m"; break;
				case '1': str ~= "\x1b[34m"; break;
				case '2': str ~= "\x1b[32m"; break;
				case '3': str ~= "\x1b[36m"; break;
				case '4': str ~= "\x1b[31m"; break;
				case '5': str ~= "\x1b[35m"; break;
				case '6': str ~= "\x1b[33m"; break;
				case '7': str ~= "\x1b[37m"; break;
				case '8': str ~= "\x1b[90m"; break;
				case '9': str ~= "\x1b[94m"; break;
				case 'a': str ~= "\x1b[92m"; break;
				case 'b': str ~= "\x1b[96m"; break;
				case 'c': str ~= "\x1b[91m"; break;
				case 'd': str ~= "\x1b[95m"; break;
				case 'e': str ~= "\x1b[93m"; break;
				case 'f': str ~= "\x1b[97m"; break;
				default: break;
			}

			continue;
		}

		if (c == '§') {
			code_next = true;
			continue;
		}

		str ~= c;
	}

	return str ~ "\x1b[0m";
}
