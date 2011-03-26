# -*- coding: utf-8 -*-
require 'test/test_helper'

module Import
  class SciImporterTest < ActiveSupport::TestCase
    context "SciImporter" do
      should 'handle correct file ' do
        wcs = SciImporter.new(File.new('test/fixtures/sci/2011.csv')).import!
        assert_equal 2, wcs.size

        wc = wcs.first
        assert wc.imported?

      end
    end
  end
end
