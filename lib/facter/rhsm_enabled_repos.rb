#!/usr/bin/ruby
#
#  Report the repos enabled to this system
#  This will be empty if the registration is bad.
#
#   Copyright 2016 Pat Riehecky <riehecky@fnal.gov>
#
#   See LICENSE for licensing.
#
begin
    require 'facter/util/facter_cacheable'
  rescue LoadError => e
    Facter.debug("#{e.backtrace[0]}: #{$!}.")
end


module Facter::Util::Rhsm_enabled_repos
  @doc=<<EOF
  Enabled RHSM repos for this client.
EOF
  class << self
    def rhsm_enabled_repos
      value = []
      begin
        reponame = ''
        output = Facter::Util::Resolution.exec(
          '/usr/sbin/subscription-manager repos')
        output.split("\n").each { |line|
          if line =~ /Repo ID:\s+(\S+)/
            reponame = $1.chomp
          elsif line =~ /.*Enabled:\s+1/
            if reponame != ''
              value.push(reponame)
              reponame = ''
            end
          end
        }
      rescue Exception => e
          Facter.debug("#{e.backtrace[0]}: #{$!}.") unless $! =~ /This system is not yet registered/
      end
      value
    end
  end
end

if File.exist? '/usr/sbin/subscription-manager'
  if Puppet.features.facter_cacheable?
    Facter.add(:rhsm_enabled_repos) do
        setcode do
        # TODO: use another fact to set the TTL in userspace
        # right now this can be done by removing the cache files
        cache = Facter::Util::Facter_cacheable.cached?(:rhsm_enabled_repos, 24 * 3600)
        if ! cache
          repos = Facter::Util::Rhsm_enabled_repos.rhsm_enabled_repos
          Facter::Util::Facter_cacheable.cache(:rhsm_enabled_repos, repos)
          repos
        else
          if cache.is_a? Array
            cache
          else
            cache["rhsm_enabled_repos"]
          end
        end
      end
    end
  else
    Facter.add(:rhsm_enabled_repos) do
        setcode { Facter::Util::Rhsm_enabled_repos.rhsm_enabled_repos }
    end
  end
end
