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

default:
	@echo 'Usual make targets are:'
	@echo ' deps         use apt-get to install dependencies'
	@echo ' compile      compile required packages from lib'
	@echo ' install      install compiled packages'
	@echo ' module       install varnish-apikey module'
	@echo ' all          perform: deps, compile, install and modules'
	@echo ' install-php  apt-get apache, php and install apikey web gui'

# Install varnish dependencies.
deps:
	echo "You may need to \"sudo make deps\""
	apt-get -y install make
	apt-get -y install autotools-dev
	apt-get -y install automake
	apt-get -y install automake1.9
	apt-get -y install libtool
	apt-get -y install autoconf
	apt-get -y install libncurses-dev
	apt-get -y install groff-base
	apt-get -y install libpcre3-dev
	apt-get -y install pkg-config
	apt-get -y install python-docutils
	# Install redis.
	apt-get -y install redis-server

compile:
# Compile varnish.
	cd lib && \
	tar -xzf varnish-3.0.2.tar.gz
	cd lib/varnish-3.0.2/ && \
	./configure && \
	make
# Compile hiredis.
	cd lib && \
	tar -xzf antirez-hiredis-v0.10.1-29-g857b269.tar.gz
	cd lib/antirez-hiredis-857b269/ && \
	make
# Compile redis plugin.
	cd lib && \
	tar -xzf zephirworks-libvmod-redis-ef73a48.tar.gz
	cd lib/zephirworks-libvmod-redis-ef73a48/ && \
	./autogen.sh && \
	./configure VARNISHSRC=../varnish-3.0.2 VMODDIR=/usr/lib/varnish/vmods
	
# Compile mhash.
	cd lib && \
	tar -xjf mhash-0.9.9.9.tar.bz2
	cd lib/mhash-0.9.9.9/ && \
	./configure 
# Compile digest plugin.
	cd lib && \
	tar -xzf varnish-libvmod-digest-0.3-1-g6fa5034.tar.gz 
# Patch digest plugin to support pipelining
	patch lib/zephirworks-libvmod-redis-ef73a48/src/vmod_redis.c lib/vmod_redis.c.pipelining.patch
	patch lib/zephirworks-libvmod-redis-ef73a48/src/vmod_redis.vcc lib/vmod_redis.vcc.pipelining.patch
	cd lib/varnish-libvmod-digest-6fa5034/ && \
	./autogen.sh && \
	./configure VARNISHSRC=../varnish-3.0.2 VMODDIR=/usr/lib/varnish/vmods

install:
	echo "You may need to \"sudo make install\""
	cd lib/varnish-3.0.2/ && make install
	cd lib/antirez-hiredis-857b269/ && make install
	cd lib/zephirworks-libvmod-redis-ef73a48/ && make && make install
	cd lib/mhash-0.9.9.9/ && make && make install
	cd lib/varnish-libvmod-digest-6fa5034/ && make && make install
# Install library so varnish can see it.
	ln -sf /usr/local/lib/libhiredis.so.0.10 /usr/local/lib/varnish/
	ln -sf /usr/local/lib/libmhash.so.2 /usr/local/lib/varnish/

install-php:
	echo "You may need to \"sudo make install-php\""
	apt-get -y install apache2
	apt-get -y install php5
	apt-get -y install libapache2-mod-php5
	apt-get -y install php5-cli
	apt-get -y install php5-cgi
	mkdir -p /var/www/apiman
	cp php/* /var/www/apiman/
	/etc/init.d/apache2 restart

# Copy vcl to varnish directory.
module:
	echo "You may need to \"sudo make module\""
	install -c vcl/varnish-apikey.vcl /etc/varnish/varnish-apikey.vcl

# Do everything
all: \
	deps \
	compile \
	install \
	module
