#!/usr/bin/env ruby

require 'xcodeproj'

project_path = 'macos/SupportBridge.xcodeproj'
project = Xcodeproj::Project.open(project_path)
target = project.targets.first

puts "🔧 Cleaning up corrupted file references..."

# Remove all bad build files with duplicated paths
files_to_remove = []
target.source_build_phase.files.each do |build_file|
  next unless build_file.file_ref
  path = build_file.file_ref.real_path.to_s rescue nil
  if path && path.include?('macos/SupportBridge/Features/macos')
    files_to_remove << build_file
  end
end

files_to_remove.each do |bf|
  puts "  Removing bad ref: #{bf.file_ref.path}"
  target.source_build_phase.files.delete(bf)
end

# Also remove from file references in groups
def remove_bad_file_refs(group)
  group.children.each do |child|
    if child.is_a?(Xcodeproj::Project::Object::PBXGroup)
      remove_bad_file_refs(child)
    elsif child.is_a?(Xcodeproj::Project::Object::PBXFileReference)
      if child.path && child.path.include?('macos/SupportBridge')
        puts "  Removing bad group ref: #{child.path}"
        child.remove_from_project
      end
    end
  end
end

project.main_group.groups.each do |g|
  remove_bad_file_refs(g) if g.name == 'SupportBridge'
end

project.save
puts "\n✅ Cleaned up bad references"

# Now add files correctly
puts "\n📁 Adding files with correct paths..."

main_group = project.main_group['SupportBridge']

new_files = [
  { basename: 'TasksView.swift', folder: 'Features/Tasks' },
  { basename: 'CreateTaskSheet.swift', folder: 'Features/Tasks' },
  { basename: 'TaskDetailSheet.swift', folder: 'Features/Tasks' },
  { basename: 'ConversationNotesView.swift', folder: 'Features/Chat' },
  { basename: 'AddNoteSheet.swift', folder: 'Features/Chat' },
  { basename: 'AgentDashboardView.swift', folder: 'Features/Dashboard' },
  { basename: 'NotificationCenterView.swift', folder: 'Features/Notifications' },
  { basename: 'ArchiveView.swift', folder: 'Features/Archive' },
  { basename: 'TemplatesLibraryView.swift', folder: 'Features/Templates' },
  { basename: 'AdvancedFilterSheet.swift', folder: 'Features/Conversations' },
  { basename: 'ConversationTimelineView.swift', folder: 'Features/Chat' },
  { basename: 'ScheduledMessagesView.swift', folder: 'Features/Chat' },
]

added = 0
new_files.each do |file_info|
  full_path = File.expand_path("macos/SupportBridge/#{file_info[:folder]}/#{file_info[:basename]}")
  
  unless File.exist?(full_path)
    puts "  ⚠️ File not found: #{full_path}"
    next
  end
  
  # Find or create the group
  group = main_group
  file_info[:folder].split('/').each do |part|
    existing = group[part]
    if existing
      group = existing
    else
      group = group.new_group(part)
    end
  end
  
  # Check if already added correctly
  already_exists = group.files.any? { |f| f.name == file_info[:basename] || f.path == file_info[:basename] }
  if already_exists
    puts "  ⏭️ Already exists: #{file_info[:basename]}"
    next
  end
  
  # Add file reference with just the basename
  file_ref = group.new_file(file_info[:basename])
  target.source_build_phase.add_file_reference(file_ref)
  
  puts "  ✅ Added: #{file_info[:folder]}/#{file_info[:basename]}"
  added += 1
end

project.save
puts "\n🎉 Done! Added #{added} new files."
