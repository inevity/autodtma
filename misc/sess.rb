#!/usr/bin/env ruby
 
require 'rubygems'
require 'hpricot'
require 'open-uri'
 
if ARGV.length < 1
  $stderr.puts "usage: #{$0} url
 
  'url' must include the protocol prefix, e.g. http://"
  exit 1
end
 
url = ARGV.shift
if url =~ %r{^(https?://)([-a-z0-9.]+(:\d+)?)(.*/)([^/]*)$}i
  $protocol = $1
  $host = $2
  $document_dir = $4
  document_url = $5
else
  $stderr.puts 'Could not parse protocol and host from URL'
  exit 1
end
 
doc = Hpricot(open(url))
 
def puts_link(uri)
  return if uri.nil?
 
  if uri =~ %r{^#{$protocol}#{$host}(.*)$}
    puts "    #{$1}"
  elsif uri !~ %r{^https?://}
    if uri =~ %r{^/}
      puts "    #{uri}"
    else
      puts "    #{$document_dir}#{uri}"
    end
  end
end
 
puts "# httperf wsesslog for #{url} generated #{Time.now}"
puts
 
puts "#{$document_dir}#{document_url}"
 
(doc/"link[@rel='stylesheet']").each do |stylesheet|
  puts_link stylesheet.attributes['href']
end
 
(doc/"style").each do |style|
  style.inner_html.scan(/@import\s+(['"])([^\1]+)\1;/).each do |match|
    puts_link match[1]
  end
end
 
(doc/"script").each do |script|
  puts_link script.attributes['src']
end
 
(doc/"img").each do |img|
  puts_link img.attributes['src']
end

