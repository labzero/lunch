require 'active_support/inflector'

module ScreenGrabber
  DO_GRAB = (ENV['SCREENS'] && ENV['SCREENS'] == 'true') || true #my_config['screens']

  def grab_screen name='', force=false
    return unless force || grab_screen?
    pic_path = "#{screens_path}/#{filename name}"
    page.save_screenshot pic_path
  rescue
    puts $!.inspect
    puts $!.backtrace
    puts "grabbing screen choked, skipping..."
  end


  def grab_screen?
    DO_GRAB == true
  end

  private

  def filename name, ext='png'
    "#{Time.new.to_i}-#{name.parameterize}.#{ext}"
  end

  def screens_path
    folder = File.expand_path("../../../screens/#{Capybara.default_driver}", __FILE__)

    unless File.exists?(folder)
      FileUtils.mkdir_p(folder)
    end

    folder
  end

  def keypress_on(elem, key, charCode = 0)
    keyCode = case key
                when :enter then 13
                else key.to_i
              end
    puts elem.base.class

    elem.base.invoke('keypress', false, false, false, false, keyCode, charCode);
  end

end

World(ScreenGrabber)


