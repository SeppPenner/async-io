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

require_relative 'endpoint'
require_relative 'ssl_socket'

module Async
	module IO
		class SSLEndpoint < Endpoint
			def initialize(endpoint, **options)
				super(**options)
				
				@endpoint = endpoint
			end
			
			def to_s
				"\#<#{self.class} #{@endpoint}>"
			end
			
			def hostname
				@options.fetch(:hostname) {@endpoint.hostname}
			end
			
			attr :endpoint
			attr :options
			
			def params
				@options[:ssl_params]
			end
			
			def context
				if context = @options[:ssl_context]
					if params = self.params
						context = context.dup
						context.set_params(params)
					end
				else
					context = ::OpenSSL::SSL::SSLContext.new
					
					if params = self.params
						context.set_params(params)
					end
				end
				
				return context
			end
			
			def bind
				@endpoint.bind do |server|
					yield SSLServer.new(server, context)
				end
			end
			
			def connect(&block)
				SSLSocket.connect(@endpoint.connect, context, hostname, &block)
			end
			
			def each
				return to_enum unless block_given?
				
				@endpoint.each do |endpoint|
					yield self.class.new(endpoint, @options)
				end
			end
		end
		
		# Backwards compatibility.
		SecureEndpoint = SSLEndpoint
		
		class Endpoint
			def self.ssl(*args, **options)
				SSLEndpoint.new(self.tcp(*args, **options), **options)
			end
		end
	end
end
