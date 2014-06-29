/*
 Copyright 2014 (C) Raster Software Vigo (Sergio Costas)

 This file is part of RSS Vala

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

	class rss_file : Object {

		private string uri;
		public Gee.List<show_data ?> shows;
		

		public rss_file(string uri) {
			this.uri = uri;
			this.shows = new Gee.ArrayList<show_data ?>();
		}
	
		public bool process_rss() {

			show_data show;
			string data="";
			xml_element element;
			string separator;

			this.shows.clear();
		
			var file = File.new_for_uri (this.uri);
			try {
				var dis = new DataInputStream (file.read ());
				string line;
				while ((line = dis.read_line (null)) != null) {
				    data+=line;
				}
			} catch (Error e) {
				return false; // can't access the RSS
			}

			var parser = new RssVala.sax_parser(data);

			bool is_atom;
			// Allow both ATOM and RSS formats
			while(true) {
				element = parser.get_next_element();
				if (element == null) {
					return false;
				}
				if (element.data == "rss") {
					is_atom = false;
					separator = "item";
					break;
				}
				if (element.data == "feed") {
					is_atom = true;
					separator = "entry";
					break;
				}
			}

			while(true) {
				element = parser.jump_to_element(separator);
				if (element == null) {
					break;
				}
				if (!element.is_open) {
					continue;
				}
				show = new show_data();
				do {
					element = parser.get_next_element();
					if (element == null) {
						break;
					}
					if (!element.is_open) {
						continue;
					}
					switch(element.data) {
					case "link":
						element = parser.get_next_element();
						show.link = element.data;
					break;
					case "description":
						element = parser.get_next_element();
						this.fill_description(element.data,show);
					break;
					case "torrent":
						this.fill_torrent(parser,show);
					break;
					}
				} while(element.data!=separator);
				if (show.check_data()) {
					this.shows.add(show);
				}
			}
			return true;
		}

		private void fill_torrent(RssVala.sax_parser parser, show_data show) {

			do {
				var element = parser.get_next_element();
				if ((element == null) || ((element.data == "torrent") && (!element.is_open))) {
					break;
				}
				if (!element.is_open) {
					continue;
				}
				switch(element.data) {
				case "fileName":
				case "filename":
					element = parser.get_next_element();
					show.filename = this.remove_cdata(element.data);
				break;
				case "magnetURI":
				case "magnetUri":
				case "magnetuti":
					element = parser.get_next_element();
					show.magnet = this.remove_cdata(element.data);
				break;
				}
			} while(true);
		}

		private void fill_description(string data, show_data show) {
			// <![CDATA[Show Name: Accused; Episode Title: Tinas Story; Season: 2; Episode: 4]]>

			string description = this.remove_cdata(data);

			var elements = description.split(";");
			foreach (var element in elements) {
				var component = element.split(":");

				var key = component[0].strip().casefold();
				if (key == "show name".casefold()) {
					show.name = component[1].strip();
				} else if (key == "episode title".casefold()) {
					show.title = component[1].strip();
				} else if (key == "season".casefold()) {
					show.season = int.parse(component[1].strip());
				} else if (key == "episode".casefold()) {
					show.episode = int.parse(component[1].strip());
				}
			}	
		}

		private string remove_cdata(string field) {

			string data = field;
			if (data.has_prefix("![CDATA[")) {
				data = data.substring(8);
				if (data.has_suffix("]]")) {
					data = data.substring(0,data.length-2);
				}
			}
			return data;
		}
	}

	class show_data : Object {

		public string? link;
		public string? magnet;
		public string? name;
		public string? title;
		public string? filename;
		public int season;
		public int episode;
		public int year;
		public RssVala.Resolution resolution;
		public RssVala.Codec codec;
		public RssVala.Source source;

		public show_data() {
			this.link = null;
			this.magnet = null;
			this.name = null;
			this.title = null;
			this.filename = null;
			this.season = -1;
			this.episode = -1;
			this.year = -1;
			this.resolution = RssVala.Resolution.UNKNOWN;
			this.codec = RssVala.Codec.UNKNOWN;
			this.source = RssVala.Source.UNKNOWN;
		}

		public bool check_data() {

			string? process_data = null;

			if ((this.link == null) && (this.magnet == null)) {
				return false;
			}
			if (this.filename != null) {
				process_data = this.filename;
			}

			if ((process_data == null) && (this.link != null)) {
				var pos = this.link.last_index_of_char('/');
				if (pos != -1) {
					process_data = this.link.substring(pos+1);
				}
			}

			if ((process_data == null) && (this.magnet != null)) {
				var elements = this.magnet.substring(8).split("&"); // remove the "magnet:?" part and cut in elements
				foreach (var e in elements) {
					if (e.has_prefix("dn")) {
						var pos = e.index_of_char('=');
						if (pos != -1) {
							process_data = e.substring(pos+1);
							break;
						}
					}
				}
			}

			if (process_data != null) {
				var nameparser = new NameParser(process_data);
				if (this.name == null) {
					this.name = nameparser.title;
				}
				if (this.season == -1) {
					this.season = nameparser.season;
				}
				if (this.episode == -1) {
					this.episode = nameparser.chapter;
				}
				this.resolution = nameparser.resolution;
				this.codec = nameparser.codec;
				this.source = nameparser.source;
			}

			return true;
		}
	}
}
