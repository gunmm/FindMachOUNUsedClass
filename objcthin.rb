require "objcthin/version"
require 'thor'
require 'rainbow'
require 'pathname'
require 'singleton'

puts Rainbow('begin:').green
path = "/Users/minzhe/Desktop/JiemianNews"
prefix = ''
arch_command = "lipo -info #{path}"
arch_output = `#{arch_command}`

arch = 'arm64'
if arch_output.include? 'arm64'
    arch = 'arm64'
    elsif arch_output.include? 'x86_64'
    arch = 'x86_64'
    elsif arch_output.include? 'armv7'
    arch = 'armv7'
end

command = "/usr/bin/otool -o #{path}"
output = `#{command}`


class_list_identifier = 'Contents of (__DATA,__objc_classlist) section'
class_refs_identifier = 'Contents of (__DATA,__objc_classrefs) section'

unless output.include? class_list_identifier
    raise Rainbow('only support iphone target, please use iphone build...').red
end

patten = /Contents of \(.*\) section/

#File.open('/Users/minzhe/Desktop/all1.txt') do |file|
#  file.each do |line|
#    if patten2.match(line)
#        puts Rainbow(line).green
#    end
#  end
#end

name_patten_string = '.*'
unless prefix.empty?
    name_patten_string = "#{prefix}.*"
end

addressPatten = /00(#{name_patten_string}) 0x(#{name_patten_string})/
namePatten = /                     name (#{name_patten_string}) (#{name_patten_string})/


vmaddress_to_class_name_patten = /^(\d*\w*)\s(0x\d*\w*)\s_OBJC_CLASS_\$_(#{name_patten_string})/

vmaddress_to_class_name_real_patten = /00(#{name_patten_string}) 0x(#{name_patten_string})/


class_list = []
class_refs = []
used_vmaddress_to_class_name_hash = {}

can_add_to_list = false
can_add_to_refs = false

output.each_line do |line|
    if patten.match(line)
        if line.include? class_list_identifier
            can_add_to_list = true
            next
            elsif line.include? class_refs_identifier
            can_add_to_list = false
            can_add_to_refs = true
            else
            break
        end
    end
    if can_add_to_list
        class_list << line
    end
    if can_add_to_refs && line
        
        if vmaddress_to_class_name_patten.match(line)
            else
            vmaddress_to_class_name_real_patten.match(line) do |m|
                unless used_vmaddress_to_class_name_hash[m[2]]
                    used_vmaddress_to_class_name_hash[m[2]] = m[2]
                end
            end
        end
        
        
    end
end

# remove cocoapods class
podsd_dummy = 'PodsDummy'

vmaddress_to_class_name_hash = {}
needName = false
keyString = ''

class_list.each do |line|
    next if line.include? podsd_dummy
    addressPatten.match(line) do |m|
        vmaddress_to_class_name_hash[m[2]] = m[2]
        keyString = m[2]
        needName = true
    end
    

    if namePatten.match(line)
        if needName
            vmaddress_to_class_name_hash[keyString] = vmaddress_to_class_name_hash[keyString] + '' + line
            needName = false
            keyString = ''
#            puts Rainbow(line).green
        end
    end
    
end

result = vmaddress_to_class_name_hash
vmaddress_to_class_name_hash.each do |key, value|
    if used_vmaddress_to_class_name_hash.keys.include?(key)
        result.delete(key)
    end
end
puts result.values
