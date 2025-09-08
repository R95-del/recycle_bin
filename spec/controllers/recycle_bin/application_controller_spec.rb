# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'RecycleBin::ApplicationController functionality' do
  describe 'class definition' do
    it 'is defined' do
      expect(RecycleBin::ApplicationController).to be_a(Class)
    end

    it 'is in RecycleBin module' do
      expect(RecycleBin::ApplicationController.name).to eq('RecycleBin::ApplicationController')
    end
  end

  if defined?(ActionController::Base)
    describe 'Rails integration' do
      it 'inherits from ActionController::Base' do
        expect(RecycleBin::ApplicationController.superclass).to eq(ActionController::Base)
      end
    end
  else
    describe 'without ActionController' do
      it 'still exists as a class' do
        expect(RecycleBin::ApplicationController).to be_a(Class)
      end
    end
  end
end
