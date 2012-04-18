require 'spec_helper'

module Kodoyanpe
  describe Config do
    it "makes default configuration values available" do
      Config.keys.should include(:architecture)
    end

    describe "#from_file" do
      it "loads configuration values from a file" do
        example_config = File.expand_path("../fixtures/example_config.rb", __FILE__)
        Config.from_file(example_config)
        Config.keys.should include(:global_host)
        Config[:template].should eq("gold")
      end
    end
  end
end
