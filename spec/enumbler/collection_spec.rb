# frozen_string_literal: true

RSpec.describe Enumbler::Collection do
  it 'returns the enumble based on its enum method' do
    e1 = Enumbler::Enumble.new(:blue_bonnet, 1)
    e2 = Enumbler::Enumble.new(:pink_hat, 2)
    ec = Enumbler::Collection.new
    ec << e1
    ec << e2

    puts '--------------------------------[ DEBUG ]---------------------------------------'
    puts e2
    puts '--------------------------------------------------------------------------------'

    expect(ec.blue_bonnet).to eq e1
    expect(ec.pink_hat).to eq e2
    expect { ec.oh_my }.to raise_error(NoMethodError)
  end
end
