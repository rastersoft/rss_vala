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
using Posix;

//project version = 0.1

void usage() {

	GLib.stdout.printf("Usage: rss_vala -c configuration_file [-t transmission_config_file] [-p transmission_password]\n");
	Posix.exit(-1);
}

int main(string[] argv) {

	bool configuration = false;
	bool transmission = false;
	bool transmission_pass = false;
	
	string? config_file = null;
	string? transmission_password = null;
	string? transmission_file = GLib.Path.build_filename(GLib.Environment.get_home_dir(),".config","transmission","settings.json");
	
	foreach(var element in argv) {
		if (element == argv[0]) {
			continue;
		}
		if (configuration) {
			configuration = false;
			config_file = element;
			continue;
		}
		if (transmission) {
			transmission = false;
			transmission_file = element;
			continue;
		}
		if (transmission_pass) {
			transmission_pass = false;
			transmission_password = element;
			continue;
		}
		switch(element) {
		case "-c":
			configuration = true;
		break;
		case "-t":
			transmission = true;
		break;
		case "-p":
			transmission_pass = true;
		break;
		default:
			usage();
		break;
		}
	}
	
	if (configuration || transmission || (config_file == null)) {
		usage();
	}

	var config = new RssVala.configuration(config_file,transmission_file);
	config.tb_pass = transmission_password;

	Gee.List<RssVala.show_data ?> shows;


	while(true) {
		config.read_configuration();

		shows = new Gee.ArrayList<RssVala.show_data ?>();

		foreach (var rss_server in config.servers) {
			var element = new RssVala.rss_file(rss_server);
			GLib.stdout.printf("Asking for %s\n",rss_server);
			element.process_rss();
			GLib.stdout.printf("Done\n");
			foreach (var item in element.shows) {
				GLib.stdout.printf("found item %s\n",item.filename);
				shows.add(item);
			}
		}

		GLib.stdout.printf("Retrieved all data.\n");
		foreach (var search_string in config.series) {

			string reg_exp_s;
		
			reg_exp_s = search_string.replace(" ","[.\\- ]");

			var reg_exp = new Regex(reg_exp_s,RegexCompileFlags.CASELESS);
			foreach(var item in shows) {
				if (reg_exp.match(item.name)) {
					if (config.check_downloaded_file(search_string,item.season,item.episode)) {
						continue; // already downloaded
					}
					if (item.magnet != null) {
						print("Adding "+item.magnet+"\n");
						RssVala.transmission.add_torrent(item.magnet,config,search_string);
						config.add_downloaded_file(search_string,item.season,item.episode);
					} else if (item.link != null) {
						print("Adding "+item.link+"\n");
						RssVala.transmission.add_torrent(item.link,config,search_string);
						config.add_downloaded_file(search_string,item.season,item.episode);
					}
				}
			}

		}
		
		sleep(3600);
		
	}
	return 0;

}
