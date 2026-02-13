require 'xcodeproj'

project_path = 'macos/SupportBridge.xcodeproj'
project = Xcodeproj::Project.open(project_path)
target = project.targets.first

group = project.main_group['SupportBridge']['Features']['Chat']

file_name = 'ImageCache.swift'

if group.find_file_by_path(file_name)
  puts "#{file_name} already tracked."
else
  file_ref = group.new_reference(file_name)
  target.add_file_references([file_ref])
  puts "Added #{file_name} to target."
end

project.save
