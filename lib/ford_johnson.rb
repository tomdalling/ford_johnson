require_relative 'ford_johnson/version'

module FordJohnson
  extend self

  def sort(elements)
    # Empty arrays and one-element arrays do not need to be sorted.
    return elements if elements.size <= 1

    # Break the input array into pairs and stragglers. Odd-sized inputs will
    # have a single straggler, and even-sized inputs will have no stragglers.
    pairs, stragglers = Pair.all_from(elements)

    # Sort within each pair.
    pairs.each do |p|
      # TODO: custom comparator
      p.swap! if p.lesser > p.greater
    end

    # Sort between pairs, recursively. Pairs sort using their greater value.
    sorted_pairs = sort(pairs)

    # Split into 'greater' and 'lesser' chains. The greater chain is also known
    # as "S" or the "main" chain. The lesser chain doesn't really have a name---
    # I've seen it called "prep" at least once. Stragglers go on the end of the
    # lesser chain (this is important because it affects insertion order later).
    greater_chain = sorted_pairs.map(&:greater)
    lesser_chain = sorted_pairs.map(&:lesser) + stragglers

    # First insertion from lesser_chain is always at the front
    greater_chain.unshift(lesser_chain.shift)

    # Insert all lesser_chain elements into greater_chain, in specially sized
    # groups, reversed, using an optimised binary search.
    group_size_enumerator = make_group_size_enumerator
    until lesser_chain.empty?
      group_size = group_size_enumerator.next
      group = lesser_chain.shift(group_size)

      group.reverse.each do |element|
        idx = binary_insert_idx(element, greater_chain, group_size)
        greater_chain.insert(idx, element)
      end
    end

    # Greater chain now contains all elements.
    greater_chain
  end

  private

    # From Wikipedia: "There are two elements [...] in the first group, and the
    # sums of sizes of every two adjacent groups form a sequence of powers of
    # two."
    #
    # Goes like: 2, 2, 6, 10, 22, 42, 86, 170, 342, 682, 1366, 2730, 5462, ...
    #
    # This is the same as the difference between adjacent values in the
    # Jacobsthal sequence.
    #
    # Can only use the first 63 values from this enumerator. The 64th value
    # overflows a 64bit integer, and Ruby can't handle array indices that big,
    # as of v2.7.2. Nobody should be using this gem to sort anywhere near that
    # many elements anyway.
    #
    def make_group_size_enumerator
      Enumerator.new do |yielder|
        previous_value = 0
        power = 1

        loop do
          next_value = 2**power - previous_value
          yielder << next_value
          previous_value = next_value
          power += 1
        end
      end
    end

    # Group size determines max_idx, restricting the search range.
    # This is the secret sauce of the whole algorithm.
    def binary_insert_idx(new_element, sorted_elements, group_size)
      min_idx = 0
      max_idx = group_size

      while min_idx != max_idx
        middle_idx = (min_idx + max_idx) / 2
        # TODO: custom comparator
        if new_element > sorted_elements[middle_idx]
          # must be somewhere after middle_idx (right branch)
          min_idx = middle_idx + 1
        else
          # must be middle_idx or earler (left branch)
          max_idx = middle_idx
        end
      end

      min_idx
    end

    class Pair
      include Comparable

      attr_reader :lesser, :greater

      def self.all_from(elements)
        doublets = elements.each_slice(2).to_a
        stragglers = (elements.size.odd? ? doublets.pop : [])
        pairs = doublets.map { |lesser, greater| new(lesser, greater) }
        [pairs, stragglers]
      end

      def initialize(lesser, greater)
        @lesser = lesser
        @greater = greater
      end

      def to_a
        [lesser, greater]
      end

      def <=>(other)
        # TODO: custom comparator
        greater <=> other.greater
      end

      def swap!
        tmp = @lesser
        @lesser = @greater
        @greater = tmp
        nil
      end
    end
end
