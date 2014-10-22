When /^I visit the root path$/ do
  visit "/?buster=#{Time.now.to_i}"
  grab_screen("visiting the root path")
end

Then(/^I should see "([^"]*)"$/) do |text|
  grab_screen("I should see #{text}")
  page.should have_content(text)
end

Then(/^I should see something like "(.*?)"$/) do |text|
  regex = text.gsub(".....",".+")
  page.text.should match(/#{regex}/)
end

Then(/^I should not see "(.*?)"$/) do |text|
  page.should_not have_content(text)
end

When(/^I press the back button$/) do
  page.evaluate_script('window.history.back()')
end

def links_from_frame frame_name, opts={limit: 20}
  cur_frame = page.find("frame[name=#{frame_name}]")

  links = nil
  within_frame cur_frame do
    links = page.all 'a'
    links = links[0..(opts[:limit]-1)].map { |l| l[:href] }
  end

  puts "found #{links.length} links"

  links
end

#fails if any link produces a response that looks like a 404 or 500
def visit_all links
  not_found = []
  server_error = []

  links.each do |link|
    puts "visiting link: #{link}"
    visit link

    grab_screen "visited #{link}"
    current_url.should == link

    if page.has_content?('404')
      not_found << link
      next
    end

    server_error << link if page.has_content?('500') || page.has_content?('rror') || page.has_content?('ception')
  end

  unless not_found.empty? && server_error.empty?
    fail "The following links responded with status 404: #{not_found.inspect} and these responded with status 500: #{server_error}"
  end
end