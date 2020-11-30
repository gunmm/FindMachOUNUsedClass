require "objcthin/version"
require 'thor'
require 'rainbow'
require 'pathname'
require 'singleton'

class Model
  attr :name, true
  attr :address, true
  attr :superAddress, true
end

puts Rainbow('begin:').green
path = "/Users/minzhe/Desktop/Meipai"
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

command = "/usr/bin/otool -arch #{arch}  -V -o #{path}"
output = `#{command}`


class_list_identifier = 'Contents of (__DATA,__objc_classlist) section'
class_refs_identifier = 'Contents of (__DATA,__objc_classrefs) section'
class_super_refs_identifier = 'Contents of (__DATA,__objc_superrefs) section'


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
namePatten = /        name           0x(#{name_patten_string}) (#{name_patten_string})/

superClassPatten = /    superclass 0x(#{name_patten_string})/

vmaddress_to_class_name_patten = /^(\d*\w*)\s(0x\d*\w*)\s_OBJC_CLASS_\$_(#{name_patten_string})/

vmaddress_to_class_name_real_patten = /00(#{name_patten_string}) 0x(#{name_patten_string})/

class_list = []
class_refs = []
class_super_refs = []

used_vmaddress_to_class_name_hash = {}

can_add_to_list = false
can_add_to_refs = false
can_add_to_super_refs = false

output.each_line do |line|
    if patten.match(line)
        if line.include? class_list_identifier
            can_add_to_list = true
            next
            elsif line.include? class_refs_identifier
            can_add_to_list = false
            can_add_to_refs = true
            can_add_to_super_refs = false
            next
            elsif line.include? class_super_refs_identifier
            can_add_to_list = false
            can_add_to_refs = false
            can_add_to_super_refs = true
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
#    if can_add_to_super_refs && line
#        if vmaddress_to_class_name_patten.match(line)
#            else
#            vmaddress_to_class_name_real_patten.match(line) do |m|
#                unless used_vmaddress_to_class_name_hash[m[2]]
#                    used_vmaddress_to_class_name_hash[m[2]] = m[2]
#                end
#            end
#        end
#    end
end


# remove cocoapods class
podsd_dummy = 'PodsDummy'

vmaddress_to_class_name_hash = {}
needName = false
keyString = ''
superAddressString = ''

class_list.each do |line|
    next if line.include? podsd_dummy
    addressPatten.match(line) do |m|
        model = Model.new
        model.address = m[2]
        vmaddress_to_class_name_hash[m[2]] = model
        keyString = m[2]
        needName = true
    end
    
    superClassPatten.match(line) do |m|
        superAddressString = m[1]
    end
    
    namePatten.match(line) do |m|
        if needName
            model = vmaddress_to_class_name_hash[keyString]
            model.superAddress = superAddressString
            model.name = m[2]
            vmaddress_to_class_name_hash[keyString] = model
            needName = false
            keyString = ''
            superAddressString = ''
        end
    end
    
end

result = vmaddress_to_class_name_hash

used_vmaddress_to_class_name_hash.each do |key, value|
    model = result[key]
    if model != nil
        if model.superAddress != nil
            if model.superAddress.include? "_OBJC_CLASS_"
                result.delete(key)
                next
            end
        end
        supermodel = vmaddress_to_class_name_hash[model.superAddress]
        if supermodel != nil
            result.delete(model.superAddress)
            result.delete(key)
            next
        end
        
        if model.name != nil
            if model.name.start_with?('_')
                result.delete(key)
                next
            end
        end
    end
    result.delete(key)
end

result.each do |key, value|
    if value.name != nil
        if value.name.start_with?('_')
            result.delete(key)
        end
        else
        result.delete(key)
    end
end

name_list = []

puts "total： "
puts result.values.count
result.values.each do |value|
    name_list << value.name
end

puts name_list.sort


