#
# Authors: Wojciech Mlynarczyk
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED.  IN NO EVENT SHALL AUTHOR OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
# OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
# SUCH DAMAGE.

# Example demostrating how to use the api library

include "/etc/varnish/varnish-apikey.vcl";

backend wikipedia {
	.host = "208.80.152.201";
	.port = "80";
}

#
# Subroutine that defines the api, key and token.
#
sub recognize_apiname_apikey_token {
	# Identify api
	if (req.url ~ "^/tomato") {
		set req.http.apiname = "tomato";
	} else if (req.url ~ "^/potato") {
		set req.http.apiname = "potato";
	} else if (req.url ~ "^/apple") {
		set req.http.apiname = "apple";
	} else {
		error 400 "Unknown api.";
	}

	# Save apikey
	set req.http.apikey = regsub(req.url, ".*[?;]apikey=([^;]*).*", "\1");

	# Save token
	set req.http.token = regsub(req.url, ".*[?;]token=([^;]*).*", "\1");
}

sub vcl_recv {
	# Validate apikey using apikey library.
	call validate_api;

	# Proxy to wikipedia to simulate api request.
	if (req.url ~ "^/tomato") {
		set req.url = "/wiki/Tomato";
	} else if (req.url ~ "^/potato") {
		set req.url = "/wiki/Potato";
	} else {
		set req.url = "/wiki/Apple";
	}

	set req.http.host = "en.wikipedia.org";
	set req.backend = wikipedia;
}
