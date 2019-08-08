module net.connection;

interface connection {
	void connect(string address, ushort port);
	ubyte[] read_some();
	void send_some(ubyte[] data);
	void disconnect();
}

class socket_connection: connection {
	import std.socket;

	override void connect(string address, ushort port) {
		sock = new TcpSocket(new InternetAddress(address, port));
	}

	override ubyte[] read_some() {
		import std.stdio;
		ubyte[4096] tmp;
		ubyte[] dest;
		while (1) {
			try {
				auto len = sock.receive(tmp);
				if (len == -1 || !len)
					break;

				dest ~= tmp[0 .. len];
			} catch (SocketException e) {
				break;
			}
		}

		return dest;
	}

	override void send_some(ubyte[] data) {
		sock.send(data);
	}

	override void disconnect() {
		sock.close();
	}

	private {
		Socket sock;
	}
}
