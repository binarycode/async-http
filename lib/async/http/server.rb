# Copyright, 2017, by Samuel G. D. Williams. <http://www.codeotaku.com>
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

require 'async/io/endpoint'
require 'async/io/stream'

require_relative 'protocol'
require_relative 'response'

module Async
	module HTTP
		class Server < Middleware
			def self.for(*args, &block)
				self.new(block, *args)
			end
			
			def initialize(app, endpoint, protocol_class = nil)
				super(app)
				
				@endpoint = endpoint
				@protocol_class = protocol_class || endpoint.protocol
			end
			
			def accept(peer, address, task: Task.current)
				peer.setsockopt(Socket::IPPROTO_TCP, Socket::TCP_NODELAY, 1)
				
				stream = Async::IO::Stream.new(peer)
				protocol = @protocol_class.server(stream)
				
				Async.logger.debug(self) {"Incoming connnection from #{address.inspect} to #{protocol}"}
				
				protocol.each do |request|
					request.remote_address = address
					# Async.logger.debug(self) {"Incoming request from #{address.inspect}: #{request.method} #{request.path}"}
					
					# If this returns nil, we assume that the connection has been hijacked.
					self.call(request)
				end
			rescue EOFError, Errno::ECONNRESET, Errno::EPIPE, Errno::EPROTOTYPE
				# Sometimes client will disconnect without completing a result or reading the entire buffer. That means we are done.
				# Errno::EPROTOTYPE is a bug with Darwin. It happens because the socket is lazily created (in Darwin).
			end
			
			def run
				@endpoint.accept(&self.method(:accept))
			end
		end
	end
end
