RSpec.describe FordJohnson do
  it 'sorts non-destructively' do
    elements = [6,2,4,9]

    result = subject.sort(elements)

    expect(result).to eq([2,4,6,9])
    expect(elements).to eq([6,2,4,9])
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

  # These are mostly optimal values (can't get any lower).
  # Source: https://github.com/decidedlyso/merge-insertion-sort
  describe 'minimises comparisons', order: :defined do
    EXHAUSTIVE_TESTING_UNTIL = 9
    OPTIMAL_MIN_COMPARISONS = {
      0 => 0, # optimal by information theory
      1 => 0, # optimal by information theory
      2 => 1, # optimal by information theory
      3 => 3, # optimal by information theory
      4 => 5, # optimal by information theory
      5 => 7, # optimal by information theory
      6 => 10, # optimal by information theory
      7 => 13, # optimal by information theory
      8 => 16, # optimal by information theory
      9 => 19, # optimal by information theory
      10 => 22, # optimal by information theory
      11 => 26, # optimal by information theory
      12 => 30, # optimal by exhaustive search
      13 => 34, # optimal by exhaustive search
      14 => 38, # optimal by exhaustive search
      15 => 42, # optimal by exhaustive search
      16 => 46,
      17 => 50,
      18 => 54,
      19 => 58,
      20 => 62, # optimal by information theory
      21 => 66, # optimal by information theory
      22 => 71, # optimal by exhaustive search
    }

    # For small n's, exhaustively test all permutations of an n-sized array.
    # For large n's that take too long to be tested exhaustively, switch to
    # randomized testing.
    exhaustives, randoms = OPTIMAL_MIN_COMPARISONS.partition { |n,_| n < 9 }

    exhaustives.each do |n, optimal_minimum_comparisons|
      specify "for n == #{n}, worst case #{optimal_minimum_comparisons} comparisons (exhaustive)" do
        1.upto(n).to_a.permutation do |input|
          expect(num_comparisons_to_sort(input)).to be <= optimal_minimum_comparisons
        end
      end
    end

    randoms.each do |n, optimal_minimum_comparisons|
      specify "for n == #{n}, worst case #{optimal_minimum_comparisons} comparisons (randomised)" do
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
