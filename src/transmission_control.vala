/*
 RSS Vala is free software; you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation; either version 3 of the License, or
 (at your option) any later version.

 RSS Vala is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with this program.  If not, see <http://www.gnu.org/licenses/>. */
 
using GLib;
using Gee;
using Soup;

namespace RssVala {

	class transmission : Object {
	
		public static void add_torrent(string URL,configuration config,string search_string) {
		
			string data;
			var dest_path = Path.build_filename(config.tb_dl_folder,search_string);
			var folder = File.new_for_path(dest_path);
			try {
				folder.make_directory_with_parents();
			} catch (Error e) {
			}

			if (config.tb_dl_folder == null) {
				data = "{\"method\":\"torrent-add\",\"arguments\":{\"filename\":\"%s\"}}".printf(URL);
			} else {
				data = "{\"method\":\"torrent-add\",\"arguments\":{\"filename\":\"%s\",\"download-dir\":\"%s\"}}".printf(URL,dest_path);
			}
			var session = new Soup.Session ();
			
			var path = Path.build_filename("http://127.0.0.1/",config.tb_rpc_url,"/rpc");
			print("Acceso a "+path+"\n");
			var uri = new Soup.URI(path);
			uri.set_port(config.tb_port);
    		var message = new Soup.Message.from_uri ("GET",uri);
    		
			session.send_message(message);
			GLib.stdout.write (message.response_body.data);
			string sessionid = message.response_headers.get("X-Transmission-Session-Id");

    		message = new Soup.Message.from_uri ("POST",uri);
    		message.request_body.append_take(data.data);
    		if (sessionid != null) {
				message.request_headers.append("X-Transmission-Session-Id", sessionid);
			}

    		session.send_message(message);
    		GLib.stdout.write (message.response_body.data);
		}
	}
}

/*
try {
        // Resolve hostname to IP address
        var resolver = Resolver.get_default ();
        var addresses = resolver.lookup_by_name (host, null);
        var address = addresses.nth_data (0);
        print (@"Resolved $host to $address\n");

        // Connect
        var client = new SocketClient ();
        var conn = client.connect (new InetSocketAddress (address, 80));
        print (@"Connected to $host\n");

        // Send HTTP GET request
        var message = @"GET / HTTP/1.1\r\nHost: $host\r\n\r\n";
        conn.output_stream.write (message.data);
        print ("Wrote request\n");

        // Receive response
        var response = new DataInputStream (conn.input_stream);
        var status_line = response.read_line (null).strip ();
        print ("Received status line: %s\n", status_line);

    } catch (Error e) {
        stderr.printf ("%s\n", e.message);
    }
*/
