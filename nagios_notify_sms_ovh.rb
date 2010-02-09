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
options[:details] = nil

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

  opts.on('-e', '--details=DETAILS', 'Details about the alert') do |details|
    options[:details] = details
  end

  opts.on('-n', '--phone=PHONE', 'Phone number to send the message') do |phone|
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

# Build the message
# ^ C fo-web13/Load Average@12:07:27 Load : 10.42 10.71 10.65 : 10.71  10 : WARNING 10.65  10 : CRITICAL

type = options[:type]
state = options[:state]
hostname = options[:hostname]
service = options[:service]
time = options[:time]
details = options[:details]
phone_number = options[:phone_number]

# Strip  the hostname
if config['strip']
  config['strip']['hostname'].each { |s| hostname.gsub!(s, '') } if config['strip']['hostname']
end

if config['replace']
  type = config['replace']['type'][type] if config['replace']['type'] and config['replace']['type'][type]
  state = config['replace']['state'][state] if config['replace']['state'] and config['replace']['state'][state]
end

message = "#{type} #{state} #{hostname}/#{service}@#{time.hour}:#{time.min} #{details}"

# Send the SMS through the OVH API

wsdl = 'https://www.ovh.com/soapi/soapi-re-1.9.wsdl'
soapi = SOAP::WSDLDriverFactory.new(wsdl).create_rpc_driver

session = soapi.login(config['ovhManager']['nicHandle'], config['ovhManager']['password'], 'en', false)
result = soapi.telephonySmsSend(session, config['ovhManager']['smsAccount'], config['ovhManager']['fromNumber'], phone_number, message, nil, nil, nil, nil)

# Logout
soapi.logout(session)
