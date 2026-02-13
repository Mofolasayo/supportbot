#!/usr/bin/env ruby

require 'xcodeproj'

project_path = 'macos/SupportBridge.xcodeproj'
project = Xcodeproj::Project.open(project_path)
target = project.targets.first

# Files to clean and re-add
files_to_fix = %w[
  TasksView.swift
  CreateTaskSheet.swift
  TaskDetailSheet.swift
  ConversationNotesView.swift
  AddNoteSheet.swift
  AgentDashboardView.swift
  NotificationCenterView.swift
  ArchiveView.swift
  TemplatesLibraryView.swift
  AdvancedFilterSheet.swift
  ConversationTimelineView.swift
  ScheduledMessagesView.swift
]

puts "🧹 Removing ALL references to new files from build phase..."

# Remove all matching build files
target.source_build_phase.files.dup.each do |build_file|
  next unless build_file.file_ref
  name = build_file.file_ref.name || build_file.file_ref.path
  if files_to_fix.any? { |f| name&.include?(f) }
    puts "  Removing: #{name}"
    target.source_build_phase.files.delete(build_file)
  end
end

puts "\n🗑️  Removing duplicated PBXFileReferences..."

# Find and remove duplicated file references
def find_and_remove_refs(group, files_to_fix, removed)
  group.children.dup.each do |child|
    if child.is_a?(Xcodeproj::Project::Object::PBXGroup)
      find_and_remove_refs(child, files_to_fix, removed)
    elsif child.is_a?(Xcodeproj::Project::Object::PBXFileReference)
      name = child.name || child.path
      if files_to_fix.any? { |f| name&.include?(f) }
        puts "  Removing ref: #{name} from #{group.name}"
        child.remove_from_project
        removed << name
      end
    end
  end
end

removed = []
project.main_group.groups.each { |g| find_and_remove_refs(g, files_to_fix, removed) }

project.save
puts "\n✅ Cleaned #{removed.count} file references"
puts "\n📁 Now manually add files to Xcode by drag-and-drop"
