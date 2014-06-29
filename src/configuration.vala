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

namespace RssVala {

	private class configuration : Object {

		public string[] servers;
		public string[] series;
		
		// Transmission Bittorrent data
		public int tb_port;
		public string? tb_user;
		public string? tb_pass;
		public bool tb_use_user;
		public string? tb_rpc_url;
		public string? tb_dl_folder;
		public string? tb_torrent_folder;
		
		private string path;
		private string config_path;
		private downloaded_element[] downloaded;

		public configuration(string path, string transmission_file) {
			this.path = path;
			this.servers = {};
			this.series = {};
			this.downloaded = {};
			
			this.tb_port = 9091;
			this.tb_user = null;
			this.tb_pass = null;
			this.tb_rpc_url = null;
			this.tb_dl_folder = null;
			this.tb_torrent_folder = null;
			this.tb_use_user = false;
			
			this.config_path = GLib.Path.build_filename(GLib.Environment.get_home_dir(),".config","rss_vala");
			this.read_downloaded_files();
			this.read_transmission_config(transmission_file);
		}

		private void read_transmission_config(string path) {
		
			var file = File.new_for_path (path);
			try {
				var dis = new DataInputStream (file.read ());
				string line;
				while ((line = dis.read_line (null)) != null) {
					var lines = line.replace(",","").split(":");
					if (lines.length != 2) {
						continue;
					}
					if (lines[0].index_of("rpc-port") != -1) {
						this.tb_port = int.parse(lines[1]);
						continue;
					}
					if (lines[0].index_of("rpc-authentication-required") != -1) {
						if (lines[1].index_of("true") != -1) {
							this.tb_use_user = true;
						}
						continue;
					}
					if (lines[0].index_of("rpc-username") != -1) {
						this.tb_user = lines[1].replace("\"","").strip();
						continue;
					}
					if (lines[0].index_of("watch-dir") != -1) {
						this.tb_torrent_folder = lines[1].replace("\"","").strip();
						continue;
					}
					if (lines[0].index_of("download-dir") != -1) {
						this.tb_dl_folder = lines[1].replace("\"","").strip();
						continue;
					}
					if (lines[0].index_of("rpc-url") != -1) {
						this.tb_rpc_url = lines[1].replace("\"","").strip();
						continue;
					}
				}
			} catch (Error e) {
				return;
			}
		}

		public bool read_configuration() {
		
			this.servers = {};
			this.series = {};

			var file = File.new_for_path (path);
			try {
				var dis = new DataInputStream (file.read ());
				string line;
				while ((line = dis.read_line (null)) != null) {
					line = line.strip();
					if (line=="") {
						continue;
					}
					if (line[0]=='#') {
						continue;
					}
				    if ((line.has_prefix("http://")) || (line.has_prefix("file:///"))) {
				    	this.servers+=line;
				    } else {
				    	this.series+=line;
				    }
				}
			} catch (Error e) {
				return true;
			}
			return false;
		}

		private bool read_downloaded_files() {
		
			this.downloaded = {};
			string? current_element = null;
		
			var file = File.new_for_path (this.config_path);
			if (!file.query_exists()) {
				return false;
			}
			try {
				var dis = new DataInputStream (file.read ());
				string line;
				while ((line = dis.read_line (null)) != null) {
					line = line.strip();
					if (line=="") {
						continue;
					}
					if (line[0]=='#') {
						continue;
					}
				    if (line[0]=='*') {
				    	current_element = line.substring(1);
				    	continue;
				    }
				    if (current_element == null) {
				    	continue;
				    }
			    	var data = line.split(" ");
			    	if (data.length != 2) {
			    		continue;
			    	}
			    	int season  = int.parse(data[0]);
			    	int chapter = int.parse(data[1]);
			    	this.add_downloaded_file(current_element,season,chapter);
				}
			} catch (Error e) {
				return true;
			}
			return false;
		}

		public bool check_downloaded_file(string name, int season, int episode) {
		
			downloaded_element? element = null;

			foreach(var tmp in this.downloaded) {
				if (tmp.element_name == name) {
					element = tmp;
					break;
				}
			}

			if (element == null) {
				return false;
			}
			return element.check_chapter_exists(season,episode);
		
		}

		public void add_downloaded_file(string name, int season, int episode) {

			downloaded_element? element = null;
			if ((season < 0) || (episode < 0)) {
				return;
			}

			foreach(var tmp in this.downloaded) {
				if (tmp.element_name == name) {
					element = tmp;
					break;
				}
			}

			if (element == null) {
				element = new downloaded_element(name);
				this.downloaded += element;
			}
			element.append_chapter(season,episode);
			this.save_downloaded_files();
		}
		
		private void save_downloaded_files() {
		
	
			var file = File.new_for_path (this.config_path);
			if (file.query_exists()) {
				file.delete();
			}
			
			var to_write = file.create(FileCreateFlags.NONE);
			foreach (var element in this.downloaded) {
			
				to_write.write(("*"+element.element_name+"\n").data);
				var chapters = element.get_chapters();
				foreach (var chapter in chapters) {
					to_write.write((chapter+"\n").data);
				}
			}
			to_write.close();
		}
	}
	
	private class downloaded_element : Object {
	
		public string element_name;
		public int[] chapters; // season*10000 + episode

		public downloaded_element(string name) {
			this.chapters = {};
			this.element_name = name;
		}
		
		public void append_chapter(int season, int episode) {
		
			if (!this.check_chapter_exists(season,episode)) {
				int val = season * 10000 + episode;
				this.chapters+=val;
			}
		}
		
		public bool check_chapter_exists(int season, int episode) {
		
			int val = season * 10000 + episode;
		
			foreach(int chapter in this.chapters) {
				if (chapter == val) {
					return true; // it exists
				}
			}
			return false;
		}
		
		public string[] get_chapters() {
		
			string[] retval = {};
		
			foreach(var val in this.chapters) {
				int season = val/10000;
				int episode = val%10000;
				retval+="%d %d".printf(season,episode);
			}
			return retval;
		}
	}
}
