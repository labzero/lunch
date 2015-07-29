# Separated into own module for ease of testing
module CropContactImagesImplementation
  # Required when subclassing Tilt::Template. Any initializations should go here.
  def prepare

  end

  # crop and resize images
  def evaluate(scope, locals, &block)
    image = MiniMagick::Image.open(file)
    height = image.height
    width = image.width
    smallest_dimension = height < width ? height : width
    image.crop("#{smallest_dimension}x#{smallest_dimension}")
    image.resize "108x108"
    new_image = File.open(image.path, 'r')
    new_image.read
  end
end

module CropContactImages
  include MiniMagick
  class Template < ::Tilt::Template
    include CropContactImagesImplementation
  end
end

