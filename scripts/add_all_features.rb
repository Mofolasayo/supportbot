#!/usr/bin/env ruby

require 'xcodeproj'

project_path = 'macos/SupportBridge.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Get the main target
target = project.targets.first

# Get the main group
main_group = project.main_group.find_subpath('SupportBridge', true)

# All new files to add
new_files = [
  # Tasks Feature
  { path: 'Features/Tasks/TasksView.swift', group: 'Features/Tasks' },
  { path: 'Features/Tasks/CreateTaskSheet.swift', group: 'Features/Tasks' },
  { path: 'Features/Tasks/TaskDetailSheet.swift', group: 'Features/Tasks' },
  
  # Notes Feature
  { path: 'Features/Chat/ConversationNotesView.swift', group: 'Features/Chat' },
  { path: 'Features/Chat/AddNoteSheet.swift', group: 'Features/Chat' },
  
  # Dashboard Feature
  { path: 'Features/Dashboard/AgentDashboardView.swift', group: 'Features/Dashboard' },
  
  # Notifications Feature
  { path: 'Features/Notifications/NotificationCenterView.swift', group: 'Features/Notifications' },
  
  # Archive Feature
  { path: 'Features/Archive/ArchiveView.swift', group: 'Features/Archive' },
  
  # Templates Feature
  { path: 'Features/Templates/TemplatesLibraryView.swift', group: 'Features/Templates' },
  
  # Advanced Filters & Timeline
  { path: 'Features/Conversations/AdvancedFilterSheet.swift', group: 'Features/Conversations' },
  { path: 'Features/Chat/ConversationTimelineView.swift', group: 'Features/Chat' },
  { path: 'Features/Chat/ScheduledMessagesView.swift', group: 'Features/Chat' }
]

added_count = 0

new_files.each do |file_info|
  file_path = "macos/SupportBridge/#{file_info[:path]}"
  
  # Check if file exists
  unless File.exist?(file_path)
    puts "⚠️  File not found: #{file_path}"
    next
  end
  
  # Find or create the group
  group_path = file_info[:group]
  group = main_group.find_subpath(group_path, true)
  
  # Check if file is already in project
  existing_ref = group.files.find { |f| f.path == File.basename(file_path) }
  
  if existing_ref
    puts "⏭️  Skipping (already exists): #{file_path}"
    next
  end
  
  # Add file reference
  file_ref = group.new_reference(file_path)
  
  # Add to build phase
  target.source_build_phase.add_file_reference(file_ref)
  
  puts "✅ Added: #{file_info[:path]}"
  added_count += 1
end

# Save the project
project.save

puts "\n🎉 Successfully added #{added_count} new files to Xcode project!"
puts "Total files processed: #{new_files.count}"
