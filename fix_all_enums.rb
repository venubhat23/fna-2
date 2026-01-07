#!/usr/bin/env ruby

puts "=== Fixing All Enum Syntax for Rails 8 ==="

# Define all the enum fixes needed
enum_fixes = [
  {
    file: "app/models/customer.rb",
    old: "enum customer_type:",
    new: "enum :customer_type,"
  },
  {
    file: "app/models/user.rb",
    old: "enum user_type:",
    new: "enum :user_type,"
  },
  {
    file: "app/models/user.rb",
    old: "enum role:",
    new: "enum :role,"
  },
  {
    file: "app/models/family_member.rb",
    old: "enum relationship:",
    new: "enum :relationship,"
  },
  {
    file: "app/models/family_member.rb",
    old: "enum gender:",
    new: "enum :gender,"
  },
  {
    file: "app/models/lead.rb",
    old: "enum current_stage,",
    new: "enum :current_stage,"
  },
  {
    file: "app/models/policy.rb",
    old: "enum policy_type:",
    new: "enum :policy_type,"
  },
  {
    file: "app/models/policy.rb",
    old: "enum insurance_type:",
    new: "enum :insurance_type,"
  },
  {
    file: "app/models/policy.rb",
    old: "enum payment_mode:",
    new: "enum :payment_mode,"
  },
  {
    file: "app/models/sub_agent.rb",
    old: "enum status:",
    new: "enum :status,"
  },
  {
    file: "app/models/report.rb",
    old: "enum report_type:",
    new: "enum :report_type,"
  }
]

enum_fixes.each do |fix|
  file_path = fix[:file]
  old_syntax = fix[:old]
  new_syntax = fix[:new]

  if File.exist?(file_path)
    content = File.read(file_path)

    if content.include?(old_syntax)
      content = content.gsub(old_syntax, new_syntax)
      File.write(file_path, content)
      puts "✅ Fixed #{file_path}: #{old_syntax} → #{new_syntax}"
    else
      puts "⏭️  #{file_path}: Already correct or not found"
    end
  else
    puts "❌ #{file_path}: File not found"
  end
end

puts "\n=== Testing All Models ==="
begin
  # Load Rails
  require_relative 'config/environment'

  Rails.application.eager_load!
  puts "✅ All models load successfully with Rails 8 compatible enum syntax!"

rescue => e
  puts "❌ Error loading models: #{e.message}"
  puts "Location: #{e.backtrace.first}"
end

puts "\n=== Enum Fix Complete ==="