#!/usr/bin/env ruby

require 'xcodeproj'

project_path = 'macos/SupportBridge.xcodeproj'
project = Xcodeproj::Project.open(project_path)
target = project.targets.first

# Get the main SupportBridge group
support_bridge_group = project.main_group['SupportBridge']
features_group = support_bridge_group['Features']

# Helper to find or create groups
def find_or_create_group(parent, name, path = nil)
  existing = parent[name]
  return existing if existing
  
  new_group = parent.new_group(name, path)
  new_group
end

# All files to add with their absolute paths
files_config = [
  { 
    abs_path: '/Users/mofolasayo-osikoya/supportbot/macos/SupportBridge/Features/Tasks/TasksView.swift',
    group_path: ['Features', 'Tasks']
  },
  { 
    abs_path: '/Users/mofolasayo-osikoya/supportbot/macos/SupportBridge/Features/Tasks/CreateTaskSheet.swift',
    group_path: ['Features', 'Tasks']
  },
  { 
    abs_path: '/Users/mofolasayo-osikoya/supportbot/macos/SupportBridge/Features/Tasks/TaskDetailSheet.swift',
    group_path: ['Features', 'Tasks']
  },
  { 
    abs_path: '/Users/mofolasayo-osikoya/supportbot/macos/SupportBridge/Features/Chat/ConversationNotesView.swift',
    group_path: ['Features', 'Chat']
  },
  { 
    abs_path: '/Users/mofolasayo-osikoya/supportbot/macos/SupportBridge/Features/Chat/AddNoteSheet.swift',
    group_path: ['Features', 'Chat']
  },
  { 
    abs_path: '/Users/mofolasayo-osikoya/supportbot/macos/SupportBridge/Features/Chat/ConversationTimelineView.swift',
    group_path: ['Features', 'Chat']
  },
  { 
    abs_path: '/Users/mofolasayo-osikoya/supportbot/macos/SupportBridge/Features/Chat/ScheduledMessagesView.swift',
    group_path: ['Features', 'Chat']
  },
  { 
    abs_path: '/Users/mofolasayo-osikoya/supportbot/macos/SupportBridge/Features/Dashboard/AgentDashboardView.swift',
    group_path: ['Features', 'Dashboard']
  },
  { 
    abs_path: '/Users/mofolasayo-osikoya/supportbot/macos/SupportBridge/Features/Notifications/NotificationCenterView.swift',
    group_path: ['Features', 'Notifications']
  },
  { 
    abs_path: '/Users/mofolasayo-osikoya/supportbot/macos/SupportBridge/Features/Archive/ArchiveView.swift',
    group_path: ['Features', 'Archive']
  },
  { 
    abs_path: '/Users/mofolasayo-osikoya/supportbot/macos/SupportBridge/Features/Templates/TemplatesLibraryView.swift',
    group_path: ['Features', 'Templates']
  },
  { 
    abs_path: '/Users/mofolasayo-osikoya/supportbot/macos/SupportBridge/Features/Conversations/AdvancedFilterSheet.swift',
    group_path: ['Features', 'Conversations']
  },
]

puts "📁 Adding files with absolute paths..."
added = 0

files_config.each do |cfg|
  # Navigate to or create the group path
  current_group = support_bridge_group
  cfg[:group_path].each do |part|
    current_group = find_or_create_group(current_group, part)
  end
  
  basename = File.basename(cfg[:abs_path])
  
  # Skip if already exists
  if current_group.files.any? { |f| f.name == basename || f.path&.include?(basename) }
    puts "  ⏭️ Already exists: #{basename}"
    next
  end
  
  # Create file reference with ABSOLUTE path
  file_ref = current_group.new_file(cfg[:abs_path])
  file_ref.source_tree = '<absolute>'
  
  # Add to target
  target.source_build_phase.add_file_reference(file_ref)
  
  puts "  ✅ Added: #{basename}"
  added += 1
end

project.save
puts "\n🎉 Successfully added #{added} files!"
