require 'json'
require './hash_recursive_merge.rb'

class Turbo
	def initialize(conf="turbo.conf")
		@conf = JSON.parse(File.read(conf))
		p @conf
	end

	def run
		Dir.glob(@conf['scenarios_path']) do |json_file|
			run_scenario(json_file)
		end
	end

	private

	def generate_header(obj)
		headers = []
		obj.each_pair do |k, v|
			headers << "-H \"#{k}: #{v}\""
		end
		headers.join(' ')
	end

	def load_common
		JSON.parse(File.read(@conf['common_conf']))
	end

	def load_scenario(scenario)
		JSON.parse(File.read(scenario))
	end

	def run_scenario(scenario)
		common = load_common
		config = common.rmerge(load_scenario(scenario))

		# generate all headers
		headers = generate_header(config['headers'])
		
		# generate HTTP method
		method = "-X #{config['method']}"

		# run each case here
		config['cases'].each do |caze|
			path = config['baseurl'] + caze['path']
			data = config['method'] == "POST" ? "-d @#{caze['data']}" : ""
			command = "curl -is #{headers} #{method} #{data} #{path}"
			puts "#{config['method']} #{path}"
			system "#{command} | ack \"#{caze['success']}\""
		end
	end
end

Turbo.new.run