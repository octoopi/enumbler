# frozen_string_literal: true

RSpec.describe Enumbler::Enumble do
  describe '#==()', '- they should be equal when' do
    context 'should be equal when' do
      example 'both have the same id' do
        e1 = described_class.new(:blue, 1)
        e2 = described_class.new(:red, 1)

        expect(e1).to eq e2
      end
      example 'both have the same enum' do
        e1 = described_class.new(:blue, 1)
        e2 = described_class.new(:blue, 2)

        expect(e1).to eq e2
      end
      example 'both have the same label' do
        e1 = described_class.new(:blue, 1, label: 'bob')
        e2 = described_class.new(:red, 2, label: 'bob')

        expect(e1).to eq e2
      end
    end
    context 'should not be equal when' do
      example 'they all have different values' do
        e1 = described_class.new(:blue, 1, label: 'bob')
        e2 = described_class.new(:red, 2, label: 'sam')

        expect(e1).not_to eq e2
      end
    end
  end

  describe '#label' do
    it 'uses a dasherized label' do
      e1 = described_class.new(:blue_bonnet, 1)
      expect(e1.label).to eq 'blue-bonnet'
    end
  end
end
