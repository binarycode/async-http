# Copyright, 2018, by Samuel G. D. Williams. <http://www.codeotaku.com>
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

require 'async/http/internet'
require 'async/reactor'

require 'json'

RSpec.describe Async::HTTP::Internet, timeout: 5 do
	include_context Async::RSpec::Reactor
	
	let(:headers) {[['accept', '*/*'], ['user-agent', 'async-http']]}
	
	after do
		subject.close
	end
	
	it "can fetch remote website" do
		response = subject.get("https://www.codeotaku.com/index", headers)
		
		expect(response).to be_success
		
		response.close
	end

	it 'can fetch remote website when given custom endpoint instead of url' do
		ssl_context = OpenSSL::SSL::SSLContext.new
		ssl_context.set_params(verify_mode: OpenSSL::SSL::VERIFY_NONE)

		# example of site with invalid certificate that will fail to be fetched without custom SSL options
		endpoint = Async::HTTP::Endpoint.parse('https://expired.badssl.com', ssl_context: ssl_context)

		response = subject.get(endpoint, headers)

		expect(response).to be_success

		response.close
	end
	
	let(:sample) {{"hello" => "world"}}
	let(:body) {[JSON.dump(sample)]}
	
	it "can fetch remote json" do
		response = subject.post("https://httpbin.org/anything", headers, body)
		
		expect(response).to be_success
		expect{JSON.parse(response.read)}.to_not raise_error
	end
end
