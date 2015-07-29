require 'rails_helper'
require 'crop_contact_images'

describe CropContactImagesImplementation do

  let(:crop_contact_images) {
    test_class = Class.new do
      include CropContactImagesImplementation
      attr_accessor :file, :data, :name
    end
    test_class.new
  }
  it { expect(crop_contact_images).to respond_to(:prepare) }
  it { expect(crop_contact_images).to respond_to(:evaluate) }

  describe "`evaluate` method" do
    let(:image) { double('image', height: 0, width: 0, crop: nil, resize: nil, path: nil) }
    let(:image_file) { double('the processed image file', read: nil) }
    let(:image_stream) { double('the image stream') }
    let(:data) { double('data') }
    before do
      allow(MiniMagick::Image).to receive(:open).and_return(image)
      allow(File).to receive(:open).and_return(image_file)
    end
    it 'opens the file using MiniMagick' do
      expect(MiniMagick::Image).to receive(:open)
      crop_contact_images.evaluate(self,{})
    end
    it 'crops the image into a square using the width as the length if it is smaller than the height' do
      allow(image).to receive(:width).and_return(50)
      allow(image).to receive(:height).and_return(100)
      expect(image).to receive(:crop).with("50x50")
      crop_contact_images.evaluate(self,{})
    end
    it 'crops the image into a square using the height as the length if it is smaller than the width' do
      allow(image).to receive(:width).and_return(150)
      allow(image).to receive(:height).and_return(100)
      expect(image).to receive(:crop).with("100x100")
      crop_contact_images.evaluate(self,{})
    end
    it 'resizes the image to `108x108`' do
      expect(image).to receive(:resize).with("108x108")
      crop_contact_images.evaluate(self,{})
    end
    it 'reads the new image file and returns the data stream' do
      allow(image_file).to receive(:read).and_return(image_stream)
      expect(crop_contact_images.evaluate(self,{})).to eq(image_stream)
    end
  end
end
