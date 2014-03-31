#!/bin/bash
#
# Authors: Wojciech Mlynarczyk, Sami Kerola
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

# Default settings, do not touch.
SCRIPT_INVOCATION_SHORT_NAME=$(basename ${0})
set -e # exit on errors
trap 'echo "${SCRIPT_INVOCATION_SHORT_NAME}: exit on error"; exit 1' ERR
set -u # disallow usage of unset variables
RETVAL=0

msg() {
	echo "${SCRIPT_INVOCATION_SHORT_NAME}: ${@}"
}

usage() {
	echo "Usage:"
	echo " ${SCRIPT_INVOCATION_SHORT_NAME} functionality [arguments]"
	echo ""
	echo "The functionalities are:"
	echo " restrict-api             api-name"
	echo " unrestrict-api           api-name"
	echo " add-user                 user-name api-key"
	echo " list-users"
	echo " view-user                user-name"
	echo " add-api                  user-name api-name"
	echo " delete-api               user-name api-name"
	echo " block-user               user-name time"
	echo " unblock-user             user-name"
	echo " block-apikey             apikey time"
	echo " unblock-apikey           apikey"
	echo " set-referer              user-name referer"
	echo " delete-referer           user-name referer"
	echo " set-security-key         user-name security-key"
	echo " delete-security-key      user-name"
	echo " set-security-timeout     user-name security-timeout"
	echo " delete-security-timeout  user-name"
	echo " clear-database"
	echo " add-group                group-name"
	echo " delete-group             group-name"
	echo " set-group                user-name group-name"
	echo " clear-group              user-name"
	echo " view-group               group-name"

	exit ${1}
}

number_of_args() {
	if [ "x${1}" != "x${2}" ]; then
		msg "incorrect number of arguments"
		msg "try \"${SCRIPT_INVOCATION_SHORT_NAME} help\" for information."
		exit 1
	fi
}

restrict-api() {
	redis-cli set api:${1}:restricted 1
}

unrestrict-api() {
	redis-cli del api:${1}:restricted
}

add-user() {
	msg "TODO: check if user exists"
	redis-cli sadd users "${1}"
	redis-cli set user:${1}:key ${2}
	redis-cli set key:${2} 1
	redis-cli set key:${2}:user ${1}
}

list-users() {
	redis-cli smembers users
}

view-user() {
	key=$(redis-cli get user:${1}:key)
	apis=$(redis-cli smembers key:${key}:api-list)
	blocked=$(redis-cli get key:${key}:blocked)
	referer=$(redis-cli get key:${key}:security:referer)
	skey=$(redis-cli get key:${key}:security:key)
	stimeout=$(redis-cli get key:${key}:security:timeout)
	group=$(redis-cli get key:${key}:group)
	msg "user-name: ${1}"
	msg "apikey: ${key}"
	msg "group: ${group}"
	msg "api list:"
	msg ${apis}
	msg "blocked: ${blocked}"
	msg "referer: ${referer}"
	msg "security-key: ${skey}"
	msg "security-timeout: ${stimeout}"
}

add-api() {
	key=$(redis-cli get user:${1}:key)
	redis-cli set key:${key}:api:${2} 1
	redis-cli sadd key:${key}:api-list ${2}
}

delete-api() {
	key=$(redis-cli get user:${1}:key)
	redis-cli del key:${key}:api:${2}
	redis-cli srem key:${key}:api-list ${2}
}

block-user() {
	key=$(redis-cli get user:${1}:key)
	redis-cli setex key:${key}:blocked ${2} 1
}

unblock-user() {
	key=$(redis-cli get user:${1}:key)
	redis-cli del key:${key}:blocked
	redis-cli set key:${key}:usage:reset 1
}

block-apikey() {
	redis-cli set key:${1}:blocked ${2} 1
}

unblock-apikey() {
	redis-cli del key:${1}:blocked
}

set-referer() {
	key=$(redis-cli get user:${1}:key)
	redis-cli set key:${key}:security:referer ${2}
}

delete-referer() {
	key=$(redis-cli get user:${1}:key)
	redis-cli del key:${key}:security:referer
}

set-security-key() {
	key=$(redis-cli get user:${1}:key)
	redis-cli set key:${key}:security:key ${2}
}

delete-security-key() {
	key=$(redis-cli get user:${1}:key)
	redis-cli del key:${key}:security:key
}

set-security-timeout() {
	key=$(redis-cli get user:${1}:key)
	redis-cli set key:${key}:security:timeout ${2}
}

delete-security-timeout() {
	key=$(redis-cli get user:${1}:key)
	redis-cli del key:${key}:security:timeout
}

clear-database() {
	redis-cli flushdb
}

add-group() {
	redis-cli set group:${1}:valid 1
	redis-cli sadd groups "${1}"
}

delete-group() {
	redis-cli del group:${1}:valid
	redis-cli srem groups "${1}"
}

set-group() {
	key=$(redis-cli get user:${1}:key)
	redis-cli set user:${1}:group ${2}
	redis-cli set key:${key}:group ${2}
	redis-cli sadd group:${2}:users "${1}"
}

clear-group() {
	key=$(redis-cli get user:${1}:key)
	group=$(redis-cli get user:${1}:group)
	redis-cli del user:${1}:group
	redis-cli del key:${key}:group
	redis-cli srem group:${group}:users "${1}"
}

view-group() {
	valid=$(redis-cli get group:${1}:valid)
	users=$(redis-cli smembers group:${1}:users)
	msg "is-valid: ${valid}"
	msg "user:"
	msg ${users}
}


# There must be at least one argument.
if [ ${#} -eq 0 ]; then
	usage 1
fi
case "${1}" in
	restrict-api)
		number_of_args ${#} 2
		restrict-api ${2}
		;;
	unrestrict-api)
		number_of_args ${#} 2
		unrestrict-api ${2}
		;;
	add-user)
		number_of_args ${#} 3
		add-user ${2} ${3}
		;;
	list-users)
		number_of_args ${#} 1
		list-users
		;;
	view-user)
		number_of_args ${#} 2
		view-user ${2}
		;;
	add-api)
		number_of_args ${#} 3
		add-api ${2} ${3}
		;;
	delete-api)
		number_of_args ${#} 3
		delete-api ${2} ${3}
		;;
	block-user)
		number_of_args ${#} 3
		block-user ${2} ${3}
		;;
	unblock-user)
		number_of_args ${#} 2
		unblock-user ${2}
		;;
	block-apikey)
		number_of_args ${#} 3
		block-apikey ${2} ${3}
		;;
	unblock-apikey)
		number_of_args ${#} 2
		unblock-apikey ${2}
		;;
	set-referer)
		number_of_args ${#} 3
		set-referer ${2} ${3}
		;;
	delete-referer)
		number_of_args ${#} 2
		delete-referer ${2}
		;;
	set-security-key)
		number_of_args ${#} 3
		set-security-key ${2} ${3}
		;;
	delete-security-key)
		number_of_args ${#} 2
		delete-security-key ${2}
		;;
	set-security-timeout)
		number_of_args ${#} 3
		set-security-timeout ${2} ${3}
		;;
	delete-security-timeout)
		number_of_args ${#} 2
		delete-security-timeout ${2}
		;;
	clear-database)
		number_of_args ${#} 1
		clear-database
		;;
	add-group)
		number_of_args ${#} 2
		add-group ${2}
		;;
	delete-group)
		number_of_args ${#} 2
		delete-group ${2}
		;;
	set-group)
		number_of_args ${#} 3
		set-group ${2} ${3}
		;;
	clear-group)
		number_of_args ${#} 2
		clear-group ${2}
		;;
	view-group)
		number_of_args ${#} 2
		view-group ${2}
		;;
	help)
		usage 0
		;;
	*)
		usage 1
		;;
esac

msg "success"

exit ${RETVAL}
# EOF
