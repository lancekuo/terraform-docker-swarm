#!/usr/bin/env ruby
# NOTICE: AWS providers only.
# Inspired from https://gist.github.com/gionn/fabbd0f6d6ad897d0338

require 'json'
require 'erb'

def get_template()
%{
<% hosts.each do |key, entry| %>
Host <%= key %>
    User <%= entry[:user] %>
    Hostname <%= entry[:hostname] %>
<% end %>
}
end

def get_template_bastion()
%{
<% hosts.each do |key, entry| %>
Host <%= key %>
    User <%= entry[:user] %>
    Hostname <%= entry[:hostname] %>
    ProxyCommand ssh -A <%= entry[:bastion_name]%> nc %h %p
    IdentityFile 
    ForwardAgent yes
<% end %>
}
end

class SshConfig
  attr_accessor :hosts

  def initialize(hosts)
    @hosts = hosts
  end

  def get_binding
    binding()
  end
end

file = File.read('terraform.tfstate')
data_hash = JSON.parse(file)

hosts = {}
bastion = {}
bastion_name = ""

data_hash['modules'][1]['resources'].each do |key, resource|
  if ['aws_instance'].include?(resource['type'])
    attributes = resource['primary']['attributes']
    name = attributes['tags.Name']
    if name.index('bastion')
      hostname = attributes['public_ip']

      user = 'ubuntu'

      bastion[name] = {
        :hostname => hostname,
        :user => user,
      }
      bastion_name = name
    end
  end
end

renderer = ERB.new(get_template)
puts renderer.result(SshConfig.new(bastion).get_binding)

data_hash['modules'][1]['resources'].each do |key, resource|
  if ['aws_instance'].include?(resource['type'])
    attributes = resource['primary']['attributes']
    name = attributes['tags.Name']
    hostname = attributes['private_ip']
    if !name.index('bastion')

      user = 'ubuntu'

      hosts[name] = {
        :hostname => hostname,
        :user => user,
        :bastion_name => bastion_name,
      }
    end
  end
end
renderer2 = ERB.new(get_template_bastion)
puts renderer2.result(SshConfig.new(hosts).get_binding)
File.write('ssh_config_'+bastion_name[0..bastion_name.index('bastion')-2], renderer.result(SshConfig.new(bastion).get_binding)+renderer2.result(SshConfig.new(hosts).get_binding))
