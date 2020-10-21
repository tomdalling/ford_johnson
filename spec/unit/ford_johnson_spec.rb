RSpec.describe FordJohnson do
  it 'sorts non-destructively' do
    elements = [6,2,4,9].freeze

    result = subject.sort(elements)

    expect(result).to eq([2,4,6,9])
  end

  it 'takes a custom comparator (copy Array#sort interface)'

  it 'performs the minimum number of comparisons for n <= 11'

  it 'doesnt have cheeky edge cases where things dont get sorted properly' do
    [4, 5].each do |input_size|
      100.times do
        inputs = Array.new(input_size) { rand(-10..10) }
        inputs.permutation do |permutation|
          permutation.freeze
          expect(subject.sort(permutation)) == permutation.sort
        end
      end
    end
  end
end
