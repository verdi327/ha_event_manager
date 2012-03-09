#Dependencies
require "csv"
require "sunlight"

#class Definition
class EventManager
  INVALID_ZIPCODE = "00000"
  INVALID_NUMBER = "0000000000"
  Sunlight::Base.api_key = "e179a6973728c4dd3fb1204283aaccb5"

  def initialize(filename)
    puts "EventManager Initialized"
    @file = CSV.open(filename, {headers: true, header_converters: :symbol})
  end

  def print_names
    @file.each do |line|
      puts "#{line[:first_name]} #{line[:last_name]}"
    end
  end

  def clean_number(original)
    number = original.delete("(.)' '-")
    if number.length == 10
      number
    elsif number == 11
      if number.start_with?('1')
        number = number[1..-1]
      else
        INVALID_NUMBER
      end
    else
      INVALID_NUMBER
    end
  end

  def print_numbers
    @file.each do |line|
      puts number = clean_number(line[:homephone])
    end
  end

  def clean_zipcode(original)
    if original.nil?
      INVALID_ZIPCODE
    elsif original.size == 4
      "0" + original
    elsif original.size == 3
      "00" + original
    else
      original
    end
  end

  def print_zipcodes
    @file.each do |line|
      zipcode = clean_zipcode(line[:zipcode])
    end
  end

  def output_data(filename)
    output = CSV.open(filename, "w")
    @file.each do |line|
      if @file.lineno == 2
        output << line.headers
      end
      line[:homephone] = clean_number(line[:homephone])
      line[:zipcode] = clean_zipcode(line[:zipcode])
      output << line
    end
  end

def rep_lookup
  20.times do
    line = @file.readline
    legislators = Sunlight::Legislator.all_in_zipcode(clean_zipcode(line[:zipcode]))
    names = legislators.collect do |leg|
      title = leg.title
      first_name = leg.firstname
      first_initial = first_name[0]
      last_name = leg.lastname
      party = leg.party
      title + " " + first_initial + ". " + last_name + " " + "(#{party})"
    end
    puts "#{line[:last_name]}, #{line[:first_name]}, #{line[:zipcode]}, #{names.join(", ")}"
  end
end

  def create_form_letters
    letter = File.open("form_letter.html", "r").read
    20.times do
      line = @file.readline
        custom_letter = letter.gsub('#first_name', "#{line[:first_name]}")
        custom_letter = custom_letter.gsub('#last_name', "#{line[:last_name]}")
        custom_letter = custom_letter.gsub('#street', "#{line[:street]}")
        custom_letter = custom_letter.gsub('#city', "#{line[:city]}")
        custom_letter = custom_letter.gsub('#state', "#{line[:state]}")
        custom_letter = custom_letter.gsub('#zipcode', "#{line[:zipcode]}")

    filename = "output/thanks_#{line[:last_name]}_#{line[:first_name]}.html"
    output = File.open(filename, 'w')
    output << custom_letter
    end
  end

  def rank_times
    hours = Array.new(24) {0}
    @file.each do |line|
      full_date = line[:regdate].split(" ")
      hour_with_minutes = full_date[1].split(":")
      hour = hour_with_minutes[0]
      hours[hour.to_i] = hours[hour.to_i] + 1
    end
    hours.each_with_index{|counter, hour| puts "#{hour}\t#{counter}"}
  end

  def rank_stats
    days = Array.new(7) {0}
    @file.each do |line|
      full_date = line[:regdate].split(" ")
      date = Date.strptime("#{full_date[0]}", "%m/%d/%Y" )
      days[date.wday] = days[date.wday] + 1
    end
    days.each_with_index{|counter, day| puts "#{day}/t#{counter}"}
  end

  def state_stats
    state_data = {}
    @file.each do |line|
      state = line[:state]
      if state.nil?
        false
      elsif state_data[state].nil?
        state_data[state] = 1
      else
        state_data[state] = state_data[state] + 1
      end
    end
    state_data = state_data.sort_by {|state,counter| state.to_s}.reverse
    state_data.each do |state,counter| puts "#{state}: #{counter}"
    end
  end

end

manager = EventManager.new("event_attendees.csv")
manager.state_stats