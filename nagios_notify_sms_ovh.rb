#!/usr/bin/env ruby

require 'yaml'
require 'soap/wsdlDriver'

# Load the config file
config = YAML.load_file(ARGV[0])

wsdl = 'https://www.ovh.com/soapi/soapi-re-1.8.wsdl'
soapi = SOAP::WSDLDriverFactory.new(wsdl).create_rpc_driver

session = soapi.login(config['ovhManager']['nicHandle'], config['ovhManager']['password'], 'en', false)


# Logout
soapi.logout(session)
