require 'mechanize'
require 'highline/import'

@myuser = ask("SIS Username:  ") { |user| user.default = "sisuser" }
@mypass = ask("SIS Password:  ") { |pass| pass.echo = false }

@count_attempts = 0

user_input = ask("Enter desired course number in format aaaa-bbb-cc:  ") { |course| course.validate = /\d{4}-\d{3}-\d{2}/
  course.default = "1016-345-01"}

temp_user_input = user_input.split('-')

a = temp_user_input[0] #college number
b = temp_user_input[1] #course number
c = temp_user_input[2] #section number


def registerCourse(course_number)
  agent = Mechanize.new
  agent.user_agent_alias = 'Windows Mozilla'
  agent.verify_mode = OpenSSL::SSL::VERIFY_NONE
  agent.basic_auth(@myuser,@mypass)
  
  sis_login = agent.get "https://sis.rit.edu/studentInfo/schedule.do?init=main"
  sis_login_homepage = sis_login.forms[0].submit

  register_link = sis_login_homepage.link_with(:text => "Register")
  
  register_page = register_link.click
  qad_link = register_page.link_with(:text => "Quick Add/Drop")
  qad_page = qad_link.click
  
  qad_form = qad_page.form_with(:action => "add.do?source=addRegister")
  qad_form.NEWCOURSE = course_number
  
  added_page = qad_form.submit
  
  if(added_page.body =~ /Course Added./)
    puts "Course " + course_number + " added successfully!"
    return true
  end  
end


loop do
  @count_attempts = @count_attempts + 1
  agent = Mechanize.new
  agent.user_agent_alias = 'Windows Mozilla'
  agent.verify_mode = OpenSSL::SSL::VERIFY_NONE
  
  #This line fools the PHP backend at RIT into thinking I actually viewed this page first
  class_list = agent.get "https://sis.rit.edu/info/info.do?init=openCourses" 
  
  #Get the course details for the particular course number
  course_details = agent.get "https://sis.rit.edu/info/courseDetail.do?init=openCourses&source=open&section=".concat(a+b+c)
  
  #Parse out how many spots available left in the course
  course_details.body.match(/Current Enrollment:[^\d]*(\d+)/)
  currently_enrolled = $1
  course_details.body.match(/Max Enrollment:[^\d]*(\d+)/)
  max_enrolled = $1
  
  #Report on what we found
  puts "Course number: " + a+"-"+b+"-"+c
  puts "Currently enrolled: " + currently_enrolled
  puts "Max enrolled: " + max_enrolled
  puts "Attempt: " + @count_attempts.to_s
  puts "System time: " + Time.now.to_s
  
=begin
    Now that we know the number of students enrolled
    and we know the max possible enrolled
    determine if there is space in the class
    and then if there is, log in to sis and
    register the course
=end
  
  
  #If there is free space -> register; otherwise -> do nothing
  if(currently_enrolled<max_enrolled)
    if(registerCourse(a+b+c)) then exit
    end
  else
    puts "Unable to register course ".concat(a+b+c+ " right now")
    sleep 3  
  end
end
  