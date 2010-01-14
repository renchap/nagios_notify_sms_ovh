#!/usr/bin/env ruby

require 'yaml'
require 'soap/wsdlDriver'
require 'optparse'
require 'optparse/time'

# Parse the options
options = Hash.new
options[:config] = nil
options[:mode] = nil
options[:hostname] = nil
options[:time] = nil
options[:service] = nil
options[:type] = nil
options[:state] = nil
options[:phone_number] = nil

opts = OptionParser.new do |opts|
  opts.banner = 'Usage: nagios_notify_sms_ovh.rb [options]'
  opts.separator ''
  opts.separator 'Options :'

  opts.on('-c', '--config=PATH', 'Path to the config file') do |config|
    options[:config] = config
  end

  opts.on('-m', '--mode=MODE', [:host, :service], 'Select alert object type (server, host)') do |mode|
    options[:mode] = mode
  end

  opts.on('-h', '--hostname=HOSTNAME', 'Hostname for which the event occurs') do |hostname|
    options[:hostname] = hostname
  end

  opts.on('-d', '--time=HH:MM:SS', Time, "Time of the event") do |time|
    options[:time] = time
  end

  opts.on('-s', '--service=SERVICE', 'Service from which the event occurs' , 'Only on service mode') do |service|
    options[:service] = service
  end

  opts.on('-t', '--type=TYPE', 'Event type') do |type|
    options[:type] = type
  end

  opts.on('-a', '--state=STATE', 'State of the service/host') do |state|
    options[:state] = state
  end

  opts.on('-n', '--phone', 'Phone number to send the message') do |phone|
    options[:phone_number] = phone
  end

  opts.on_tail('-h', '--help', 'Show this message') do
    puts opts
    exit
  end
end

begin
  opts.parse!(ARGV)
rescue OptionParser::ParseError => e
  abort e.message+"\nTry --help for a list of options"
end

# Check if all arguments are here
class MissingArg < Exception
end
begin
  raise MissingArg, 'You must specify a config file' if options[:config] == nil
  raise MissingArg, 'You must choose a mode' if options[:mode] == nil
  raise MissingArg, 'You must specify a hostname' if options[:hostname] == nil
  raise MissingArg, 'You must specify a time' if options[:time] == nil
  raise MissingArg, 'You must specify an event type' if options[:type] == nil
  raise MissingArg, 'You must specify a state' if options[:type] == nil
  raise MissingArg, 'You must speficy a phone number' if options[:phone_number] == nil

  if options[:mode] == :service
    raise MissingArg, 'You most specity a service name' if options[:service] == nil
  end
rescue MissingArg => e
  abort 'Error : '+e.message+"\nTry --help for a list of options"
end
# Load the config file
config = YAML.load_file(options[:config])

wsdl = 'https://www.ovh.com/soapi/soapi-re-1.8.wsdl'
soapi = SOAP::WSDLDriverFactory.new(wsdl).create_rpc_driver

session = soapi.login(config['ovhManager']['nicHandle'], config['ovhManager']['password'], 'en', false)


# Logout
soapi.logout(session)
