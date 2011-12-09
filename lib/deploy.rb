#!/bin/env ruby

require 'rubygems'
require 'fileutils'
require 'json'
require 'net/http'


def stopdaemon(daemon)
	puts "Stopping #{daemon}"
	status = `/sbin/service #{daemon} start`
end

def startdaemon(daemon)
	puts "Starting #{daemon}"
	status = `/sbin/service #{daemon} stop`
end

def cleanupapp(application)
	puts "Cleaning #{application} files, directories and working cache from Tomcat"
	delete "/var/lib/tomcat6/webapps/#{application}.war"
	delete "/var/lib/tomcat6/webapps/#{application}"
	delete "/var/cache/tomcat6/work/Catalina/localhost/#{application}"
end

def queryavailableapp(application)
	puts "Available versions of #{application} from Artifactory are:"
	response = Net::HTTP.get_response("uukd3v-bldapp01.i3-dev.net","/artifactory/api/search/artifact?name=#{application}*.war",8080)
	data = response.body
	resulthash = JSON.parse(data)
	if resulthash.has_key? 'Error'
		raise "web service error"
    	end
	result = resulthash["results"]
    	result.each do |uri|
		puts uri.values
	end
    #return result
end

def fetchapp(application,url)
	puts "Fetching #{application} from #{url}"
	rawuri = URI.parse(url)
	rawresponse = Net::HTTP.get_response(rawuri.host,rawuri.path,rawuri.port)
	rawdata = rawresponse.body
	rawhash = JSON.parse(rawdata)
	if rawhash.has_key? 'Error'
                raise "web service error"
        end
	uri = URI.parse(rawhash["downloadUri"])
	Net::HTTP.start(uri.host,uri.port) do |http|
		response = http.get(uri.path)
		open(application,"wb") do |file|
			file.write(response.body)
		end
	end
end

def getcurrentappversion(application)
	puts "Reading version of #{application} from /var/lib/tomcat6/webapps/#{application}/META-INF/MANIFEST.MF"
	filename = "/var/lib/tomcat6/webapps/#{application}/META-INF/MANIFEST.MF"
	txt = File.open(filename)
	puts txt.read()
end

def delete(filename)
  Dir["#{File.dirname(filename)}/*"].each do |file|
    next if File.basename(file) == File.basename(filename)
    FileUtils.rm_rf file, :noop => true, :verbose => true
  end
end

stopdaemon("tomcat6")
cleanupapp("hnportal")
queryavailableapp("hnportal")
fetchapp("hnportal.war","http://uukd3v-bldapp01.i3-dev.net:8080/artifactory/api/storage/libs-releases-local/com/uhc/hnportal/1.4.1/hnportal-1.4.1.war")
getcurrentappversion("hnportal")	

