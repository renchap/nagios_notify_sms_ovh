#!/usr/bin/env ruby

require 'yaml'
require 'soap/wsdlDriver'
require 'optparse'
require 'optparse/time'
require 'net/smtp'

# Get rid of the SSL errors
class Net::HTTP
  alias_method :old_initialize, :initialize
  def initialize(*args)
    old_initialize(*args)
    @ssl_context = OpenSSL::SSL::SSLContext.new
    @ssl_context.verify_mode = OpenSSL::SSL::VERIFY_NONE
  end
end

# Parse the options
options = Hash.new
options[:config] = nil
options[:dont_send_sms] = false

opts = OptionParser.new do |opts|
  opts.banner = 'Usage: nagios_notify_sms_ovh.rb [options]'
  opts.separator ''
  opts.separator 'Options :'

  opts.on('-c', '--config=PATH', 'Path to the config file') do |config|
    options[:config] = config
  end

  opts.on('--dont-send-sms', 'Dont send the SMS') do |send|
    options[:dont_send_sms] = true
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

rescue MissingArg => e
  abort 'Error : '+e.message+"\nTry --help for a list of options"
end

# Load the config file
config = YAML.load_file(options[:config])

begin
  wsdl = 'https://www.ovh.com/soapi/soapi-re-1.9.wsdl'
  soapi = SOAP::WSDLDriverFactory.new(wsdl).create_rpc_driver
  
  session = soapi.login(config['ovhManager']['nicHandle'], config['ovhManager']['password'], 'en', false)

  #check the number of SMS left
  smsleft = soapi.telephonySmsCreditLeft(session, config['ovhManager']['smsAccount']).to_i
  if smsleft < config['credit']['threshold'] then
    msg = "only #{smsleft} credits left for the nagios SMS alert !"
    puts msg
    Net::SMTP.start(config['errorMail']['server']) do |smtp|
      smtp.send_message(msg, config['errorMail']['from'], config['errorMail']['to'])
    end
  end
end
# Logout
soapi.logout(session)
