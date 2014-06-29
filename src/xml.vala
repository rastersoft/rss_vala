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

namespace RssVala {

	class sax_parser : Object {

		string xml;
		int pos;
		int remainder;
		int length;

		public sax_parser(string data) {

			this.xml = data;
			this.pos = 0;
			this.length = data.length;
			this.remainder = this.length-1;
		}

		public xml_element? get_next_element() {
		
			char character;
			int origin;
			xml_element element;
			bool no_param;

			if (this.remainder <= 0) {
				return null;
			}

			character = this.xml[this.pos];
			
			element = new xml_element();
			
			if (character != '<') { // not an xml element
			
				origin=this.pos;

				while((character != '<') && (remainder > 0)) {
					this.pos++;
					this.remainder--;
					character = this.xml[this.pos];
				}
				
				element.is_xml = false;
				element.data = this.xml.substring(origin,this.pos-origin);
				return element;
			}

			element.is_xml = true;
			if (remainder<2) {
				element.is_open = true;
				element.data = "";
				remainder = 0;
				return element;
			}

			if ((this.xml[this.pos+1]=='!') || (this.xml[this.pos+1]=='?')) {
				no_param = true;
			} else {
				no_param = false;
			}

			// jump over blank spaces after the '<'
			do {
				this.pos++;
				this.remainder--;
				character = this.xml[this.pos];
			} while ((character == ' ') && (this.remainder > 0));

			if (this.remainder == 0) {
				element.data = "";
				return element;
			}

			if (character=='/') {
				element.is_open=false;
				element.is_autoclose=false;
				this.pos++;
				this.remainder--;
				character = this.xml[this.pos];
			} else {
				element.is_open=true;
			}

			// jump over blank spaces after the '/'
			while ((character == ' ') && (this.remainder > 0)) {
				this.pos++;
				this.remainder--;
				character = this.xml[this.pos];
			}

			if (this.remainder == 0) {
				element.data = "";
				return element;
			}

			origin=this.pos;
			while((character != '>') && (remainder > 0)) {
				this.pos++;
				this.remainder--;
				character = this.xml[this.pos];
			}

			string content;
			if (this.xml[this.pos-1] == '/') {
				element.is_autoclose = true;
				content = this.xml.substring(origin,this.pos-origin-1);
			} else {
				content = this.xml.substring(origin,this.pos-origin);
			}

			int space;
			
			space = content.index_of_char(' ');
			if ((space == -1) || no_param) {
				element.data = content; // no parameters
			} else {
				element.data = content.substring(0,space);
				element.parameters = content.substring(space+1);
			}

			if (remainder > 0) {
				this.pos++;
				this.remainder--;
			}
			return element;
		}

		public xml_element? jump_to_element(string xml_element) {
		
			while(true) {
				var element = this.get_next_element();
				if (element == null) {
					return null; // not found
				}
				if ((element.data != null) && (element.data == xml_element)) {
					return element;
				}
			}
		}
	}

	class xml_element : Object {
	
		public string? data;
		public string? parameters;
		public bool is_xml;
		public bool is_open;
		public bool is_autoclose;
	
		public xml_element() {

			this.is_xml = false;
			this.is_open = false;
			this.is_autoclose = false;
			this.parameters = null;
			this.data = null;
		}
	
	}

}
