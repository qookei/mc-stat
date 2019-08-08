module connection_iface;

interface connection {
	void connect(string address, ushort port);
	byte[] read_some();
	void send_some(byte[] data);
	void disconnect();
}

class socket_connection: connection {
	import std.socket;

	override void connect(string address, ushort port) {
		sock = new TcpSocket(new InternetAddress(address, port));
	}

	override byte[] read_some() {
		byte[4096] tmp;
		byte[] dest;
		while (1) {
			auto len = sock.receive(tmp);
			dest ~= tmp[0 .. len];
			if (len < 4096)
				break;
		}

		return dest;
	}

	override void send_some(byte[] data) {
		sock.send(data);
	}

	override void disconnect() {
		sock.close();
	}

	private {
		Socket sock;
	}
}
