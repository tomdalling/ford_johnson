RSpec.describe FordJohnson do
  it 'sorts non-destructively' do
    elements = [6,2,4,9].freeze

    result = subject.sort(elements)

    expect(result).to eq([2,4,6,9])
  end

  it 'takes a custom comparator block like Array#sort does' do
    inputs = %w(rhinoceros cat giraffe koala kangaroo)
    results = subject.sort(inputs) do |left, right|
      left.length <=> right.length
    end
    expect(results).to eq(%w(cat koala giraffe kangaroo rhinoceros))
  end

  it 'doesnt have cheeky edge cases where things dont get sorted properly' do
    1.upto(100) do |n|
      100.times do
        input = Array.new(n) { rand(1..99) }
        expected = input.sort
        expect(subject.sort(input)) == expected
      end
    end
  end

  # These are the optimal values (can't get any lower) according to
  # information theory and some exhaustive searching.
  # Source: https://github.com/decidedlyso/merge-insertion-sort
  describe 'minimises comparisons', order: :defined do
    EXHAUSTIVE_TESTING_UNTIL = 9
    OPTIMAL_MIN_COMPARISONS = {
      0 => 0,
      1 => 0,
      2 => 1,
      3 => 3,
      4 => 5,
      5 => 7,
      6 => 10,
      7 => 13,
      8 => 16,
      9 => 19,
      10 => 22,
      11 => 26,
      12 => 30,
      13 => 34,
      14 => 38,
      15 => 42,
    }

    # exhaustively test all permutations of an n-sized array,
    # up until n == EXHAUSTIVE_TESTING_UNTIL. Beyond that it just takes too
    # long.
    (0...EXHAUSTIVE_TESTING_UNTIL).each do |n|
      optimal_minimum_comparisons = OPTIMAL_MIN_COMPARISONS.fetch(n)

      specify "when n == #{n}, with worst case #{optimal_minimum_comparisons} comparisons (exhaustive)" do
        1.upto(n).to_a.permutation do |input|
          expect(num_comparisons_to_sort(input)).to be <= optimal_minimum_comparisons
        end
      end
    end

    # Randomised testing for n >= EXHAUSTIVE_TESTING_UNTIL. Just tries a bunch
    # of random n-sized arrays.
    (EXHAUSTIVE_TESTING_UNTIL..OPTIMAL_MIN_COMPARISONS.keys.max).each do |n|
      optimal_minimum_comparisons = OPTIMAL_MIN_COMPARISONS.fetch(n)

      specify "when n == #{n}, with worst case #{optimal_minimum_comparisons} comparisons (randomised)" do
        input = Array.new(n) { rand(1..99) }
        10_000.times do
          input.shuffle!
          expect(num_comparisons_to_sort(input)).to be <= optimal_minimum_comparisons
        end
      end
    end

    def num_comparisons_to_sort(input)
      count = 0
      comparator = ->(left, right) do
        count += 1
        left <=> right
      end
      described_class.sort(input, &comparator)
      count
    end
  end
end
