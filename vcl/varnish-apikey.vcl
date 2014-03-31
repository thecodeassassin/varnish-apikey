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

# Library for authorization based on api key

C{
#include <time.h>
#include <sys/time.h>
#include <stdio.h>
#include <stdlib.h>
}C

import redis;
import std;
import digest;

#
# Public subroutine to be called from user code to validate the api.
#
sub validate_api {
	# This subroutine is provided by the user it should set
	# headers: apiname, apikey, token
	call recognize_apiname_apikey_token;

	# Get variables from redis.
	call apikey_call_redis;

	# Do the work.
	if (req.http.restricted == "1") {
		call apikey_check_apikey;
		call apikey_check_throttling;
		call apikey_check_referer;
		call apikey_check_security;
	}

	# Delete the headers.
	call apikey_unset_headers;
}

# Call redis and get all keys.
sub apikey_call_redis {

	# Settings. Hardcoded for a moment. Will be read from database in the future.

	set req.http.blocked_time   = "60"; #redis.call("GET settings:blocked:time");
	set req.http.num_instances  = "1";  #redis.call("GET settings:instances");
	set req.http.counter_time   = "60"; #redis.call("GET key:" + req.http.apikey + ":usage:" + req.http.apiname + ":time");

	# Per api.
	# Use pipelining mode (make all calls first and then get results in bulk).

	redis.pipeline();

	redis.push("GET api:" + req.http.apiname + ":restricted");
	redis.push("GET key:" + req.http.apikey);
	redis.push("GET key:" + req.http.apikey + ":blocked");
	redis.push("GET key:" + req.http.apikey + ":api:all");
	redis.push("GET key:" + req.http.apikey + ":api:" + req.http.apiname);
	redis.push("INCR key:" + req.http.apikey + ":usage:" + req.http.apiname + ":count");
	redis.push("GET key:" + req.http.apikey + ":usage:" + req.http.apiname + ":max");
	redis.push("GET key:"  + req.http.apikey + ":usage:" + req.http.apiname + ":reset");
	redis.push("GET key:"  + req.http.apikey + ":security:referer");
	redis.push("GET key:"  + req.http.apikey + ":security:key");
	redis.push("GET key:"  + req.http.apikey + ":security:timeout");

	set req.http.restricted       = redis.pop();
	set req.http.apikey_exists    = redis.pop();
	set req.http.apikey_blocked   = redis.pop();
	set req.http.apikey_all       = redis.pop();
	set req.http.apikey_api       = redis.pop();
	set req.http.counter_count    = redis.pop();
	set req.http.counter_max      = redis.pop();
	set req.http.counter_reset    = redis.pop();
	set req.http.security_referer = redis.pop();
	set req.http.security_key     = redis.pop();
	set req.http.security_timeout = redis.pop();
}

sub apikey_check_apikey {
	# Check if api key exists.
	if (req.http.apikey_exists != "1") {
		error 401 "Unknown api key.";
	}

	# Check if api key is blocked.
	if (req.http.apikey_blocked == "1") {
		error 401 "Api key teporarily blocked.";
	}

	# Check if is allowed to use the api.
	if (req.http.apikey_all != "1" && req.http.apikey_api != "1") {
		error 401 "Api not allowed for this api key.";
	}
}

sub apikey_check_throttling {
	# Check if should reset throttling counter.
	if (req.http.counter_reset != "1") {
		redis.pipeline();
		# Reset counter.
		redis.push("SET key:" + req.http.apikey + ":usage:" + req.http.apiname + ":count 0");
		# Set timer to reset the counter
		redis.push("SETEX key:" + req.http.apikey + ":usage:" + req.http.apiname + ":reset " + req.http.counter_time + " 1");
		# Ignore results
		redis.pop2();
		redis.pop2();
	} else {
		# If exceeded number of calls then block.
		if (std.integer(req.http.counter_count, 0) > std.integer(req.http.counter_max, 0)) {
			redis.pipeline();
			# Block api key for some time
			redis.push("SETEX key:" + req.http.apikey + ":blocked " + req.http.blocked_time + " 1");
			# Reset timer
			redis.push("DEL key:" + req.http.apikey + ":usage:" + req.http.apiname + ":reset");
			# Ignore results
			redis.pop2();
			redis.pop2();
		}
	}
}

# curl --referer http://www.aaaa.bbb http://localhost:81/tomato?apikey=myapikey
sub apikey_check_referer {
	# Referer
	if (req.http.security_referer && req.http.referer) {
		# Compare main domain name (get aaa.bbb from www.aaa.bbb)
		set req.http.tmp = regsub(req.http.referer, "^http://([^/^:]*).*", "\1");
		if (req.http.security_referer != regsub(req.http.tmp, "^.*?([^.]+\.[^.]+)$", "\1")) {
			error 401 "Wrong referer";
		}
	}
}

# Check that it works.
#echo -n aaa127.0.0.1$(expr $(date +%s) / 60) | md5sum
sub apikey_check_security {
	# Token by IP.
	if (req.http.security_key && !req.http.security_timeout) {
		if (digest.hash_md5(req.http.security_key + client.ip) != req.http.token) {
			error 401 "Wrong token. Correct token is: " +
			    digest.hash_md5(req.http.security_key + client.ip) + ". Use md5(password + ip) to create the token.";
		}
	}

	# Token by IP and time.
	if (req.http.security_key && req.http.security_timeout) {
		# Get time and save to headers.
		C{
			int timeout = atoi(VRT_GetHdr(sp, HDR_REQ, "\021security_timeout:"));
			if (timeout <= 1 || timeout > 999999) {
				timeout = 1;
			}

			struct timeval tv;
			gettimeofday(&tv, NULL);
			int t = tv.tv_sec / timeout;
			char buf[100];
			snprintf(buf, sizeof(buf), "%d", t);

			VRT_SetHdr(sp, HDR_REQ, "\003t1:", buf, vrt_magic_string_end);
			snprintf(buf, sizeof(buf), "%d", t - 1);
			VRT_SetHdr(sp, HDR_REQ, "\003t2:", buf, vrt_magic_string_end);
			snprintf(buf, sizeof(buf), "%d", t + 1);
			VRT_SetHdr(sp, HDR_REQ, "\003t3:", buf, vrt_magic_string_end);
		}C
		if (digest.hash_md5(req.http.security_key + client.ip +
				      req.http.t1) != req.http.token
		      && digest.hash_md5(req.http.security_key + client.ip +
					 req.http.t2) != req.http.token && digest.hash_md5(req.http.security_key + client.ip + req.http.t3) != req.http.token) {
			error 401 "Wrong token. Correct token is: " +
			    digest.hash_md5(req.http.security_key + client.ip + req.http.t1) + ". Use md5(password + ip + time) to create the token.";
		}
	}
}

sub apikey_unset_headers {
	unset req.http.apiname;
	unset req.http.apikey;
	unset req.http.token;
}
