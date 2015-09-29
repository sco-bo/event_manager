require 'csv'
require 'sunlight/congress'
require 'erb'
require 'date'

@popular_hours = Array.new
@popular_days = Array.new

Sunlight::Congress.api_key = "e179a6973728c4dd3fb1204283aaccb5"

def clean_registration_date(date)
  clean_date = DateTime.strptime(date, '%m/%d/%y %H:%M')
  @popular_hours << clean_date.hour
  @popular_days << clean_date.wday
end

def most_popular_hour
  count = @popular_hours.inject(Hash.new(0)) {|k,v| k[v] += 1; k}
  puts "The most popular time to register is at #{@popular_hours.max_by {|v| count[v]}}:00"
end

def most_popular_day
  count = @popular_days.inject(Hash.new(0)) {|k,v| k[v] += 1; k}
  popular_day = @popular_days.max_by {|v| count[v]}
  puts "The most popular day of the week to register is #{number_to_day(popular_day)} "
end

def number_to_day(num)
  case num
  when 0
    "Sunday"
  when 1
    "Monday"
  when 2
    "Tuesday"
  when 3
    "Wednesday"
  when 4
    "Thursday"
  when 5
    "Friday"
  when 6
    "Saturday"
  else
    "Error"
  end 
end

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, "0")[0..4]
end

def clean_phone_numbers(homephone)
  clean_number = homephone.to_s.gsub!(/\D/, '')
  if clean_number.nil?
    clean_number = "0000000000"
  elsif clean_number.length == 10
    clean_number
  elsif clean_number.length > 10 && clean_number[0] == "1"
    clean_number[0] = ''
  else
    clean_number = "0000000000"
  end
end

def legislators_by_zipcode(zipcode)
  Sunlight::Congress::Legislator.by_zipcode(zipcode)
end

def save_thank_you_letters(id,form_letter)
  Dir.mkdir("output") unless Dir.exists?("output")
  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

puts "EventManager Initialized"

contents = CSV.open "event_attendees.csv", headers: true, header_converters: :symbol

template_letter = File.read "form_letter.erb"
erb_template = ERB.new template_letter

contents.each do |row|
  id = row[0]
  registration_date = clean_registration_date(row[:regdate])
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  phone_number = clean_phone_numbers(row[:homephone])
  legislators = legislators_by_zipcode(zipcode)
  form_letter = erb_template.result(binding)
  save_thank_you_letters(id, form_letter)
end

most_popular_hour
most_popular_day
