#!/usr/bin/env ruby

require 'xcodeproj'

project_path = 'macos/SupportBridge.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Get the main target
target = project.targets.first

puts "Removing incorrectly added file references..."

# Remove all file references from build phase
target.source_build_phase.files.each do |build_file|
  if build_file.file_ref && build_file.file_ref.path && build_file.file_ref.path.include?('macos/SupportBridge/Features')
    puts "Removing: #{build_file.file_ref.path}"
    target.source_build_phase.files.delete(build_file)
  end
end

# Save to remove bad references
project.save

puts "\n✅ Cleaned up bad references"
puts "Now re-run add_all_features.rb to add them correctly"
