base = File.expand_path(File.dirname(__FILE__) + '/../lib')
require base + '/nagios_config'
require 'benchmark'

objects = "# example
define host {
host_name      example.com
alias          example
use            defaults
check_command  ping
}\n\n" * 500

main = "# LOG FILE
log_file=/foo/bar/baz/nagios/nagios.log


# OBJECT CONFIGURATION FILE(S)
# This is the configuration file in which you define hosts, host
# groups, contacts, contact groups, services, etc.  

cfg_file=checkcommands.cfg
cfg_file=misccommands.cfg

cfg_file=contactgroups.cfg
cfg_file=contacts.cfg

#cfg_file=dependencies.cfg
#cfg_file=escalations.cfg

cfg_file=hostgroups.cfg
cfg_file=hosts.cfg
cfg_file=services.cfg

cfg_file=timeperiods.cfg


# OBJECT CACHE FILE
# This option determines where object definitions are cached when
# Nagios starts/restarts.  The CGIs read object definitions from 
# this cache file (rather than looking at the object config files
# directly) in order to prevent inconsistencies that can occur
# when the config files are modified after Nagios starts.

object_cache_file=/foo/bar/baz/nagios/objects.cache\n\n" * 50

Benchmark.bm(38) do |x|
  x.report("objects") do
    5.times do
      NagiosConfig::Parser.new.parse(objects)
    end
  end
  
  x.report("main") do
    5.times do
      NagiosConfig::Parser.new.parse(main)
    end
  end
  
  x.report("objects (ignore comments & whitespace)") do
    5.times do
      NagiosConfig::Parser.new(true).parse(objects)
    end
  end
  
  x.report("main (ignore comments & whitespace)") do
    5.times do
      NagiosConfig::Parser.new(true).parse(main)
    end
  end
end