require 'xcodeproj'

project_path = 'macos/SupportBridge.xcodeproj'
project = Xcodeproj::Project.open(project_path)
target = project.targets.first

# Group path in Xcode (matches filesystem usually)
# Main Group -> SupportBridge -> Features -> Chat
# Note: Main Group usually has name 'SupportBridge' or is implied.
# Let's traverse.

main_group = project.main_group
# Usually main_group contains 'SupportBridge' folder ref
app_group = main_group['SupportBridge']
features_group = app_group['Features']
chat_group = features_group['Chat']

files_to_add = ['AudioRecorder.swift', 'LinkPreviewService.swift']

files_to_add.each do |file|
  if chat_group.find_file_by_path(file)
    puts "#{file} already tracked."
  else
    file_ref = chat_group.new_reference(file)
    target.add_file_references([file_ref])
    puts "Added #{file} to target."
  end
end

project.save
