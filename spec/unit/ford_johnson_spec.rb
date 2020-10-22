RSpec.describe FordJohnson do
  it 'sorts non-destructively' do
    elements = [6,2,4,9].freeze

    result = subject.sort(elements)

    expect(result).to eq([2,4,6,9])
  end

  it 'doesnt have cheeky edge cases where things dont get sorted properly' do
    1.upto(100) do |input_size|
      100.times do
        input = Array.new(input_size) { rand(1..99) }
        expected = input.sort
        expect(subject.sort(input)) == expected
      end
    end
  end

  it 'takes a custom comparator like Array#sort does' do
    inputs = %w(rhinoceros cat giraffe koala kangaroo)
    results = subject.sort(inputs) do |left, right|
      left.length <=> right.length
    end
    expect(results).to eq(%w(cat koala giraffe kangaroo rhinoceros))
  end

  # TODO: check the input [9,56,84,84,36,34,13,60,58,52,18]
  # The straggler may result in extra comparisons than the theoretical minimum.
  it 'performs the minimum number of comparisons for n <= 11'

end
