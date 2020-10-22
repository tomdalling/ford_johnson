require_relative 'ford_johnson/version'

module FordJohnson
  extend self

  def sort(elements, &comparator)
    # Empty arrays and one-element arrays do not need to be sorted.
    return elements if elements.size <= 1

    comparator ||= DEFAULT_COMPARATOR

    # Break the input array into pairs and stragglers. Odd-sized inputs will
    # have a single straggler, and even-sized inputs will have no stragglers.
    pairs, stragglers = Pair.all_from(elements)

    # Sort within each pair.
    pairs
      .select { |p| greater_than?(p.left, p.right, comparator) }
      .each(&:swap!)

    # Sort between pairs, recursively. Pairs sort using their greater value.
    sorted_pairs = sort(pairs) do |left, right|
      comparator.call(left.right, right.right)
    end

    # Split into 'greater' and 'lesser' chains. The greater chain is also known
    # as "S" or the "main" chain. The lesser chain doesn't really have a name---
    # I've seen it called "prep" at least once. Stragglers go on the end of the
    # lesser chain (this is important because it affects insertion order later).
    greater_chain = sorted_pairs.map(&:right)
    lesser_chain = sorted_pairs.map(&:left) + stragglers

    # First insertion from lesser_chain is always at the front
    greater_chain.unshift(lesser_chain.shift)

    # Insert all lesser_chain elements into greater_chain, in a special order,
    # using an optimised binary search
    each_insertion_for(lesser_chain) do |element, max_idx|
      idx = binary_insert_idx(element, greater_chain, max_idx, comparator)
      greater_chain.insert(idx, element)
    end

    # Greater chain now contains all elements.
    greater_chain
  end

  private

    DEFAULT_COMPARATOR = ->(left, right) { left <=> right }

    def greater_than?(left, right, comparator)
      comparator.call(left, right) > 0
    end

    #
    # Yields successive, specially-ordered pairs of [element, max_insertion_idx]
    #
    # This is the secret sauce of the whole algorithm.
    #
    # `max_insertion_idx` is always one less than a power of two. This results
    # in an optimal binary search that requires the minumum number of
    # comparisons.
    #
    # To achieve this, elements must be inserted in groups that share the same
    # max insertion idx. However, inserting an element _increases_ the max
    # insertion idx by one for each following element. To avoid this increase,
    # elements within a group must be inserted in reverse order. This still
    # increases the max insertion idx for the next group, but this algorithm
    # increases it in such a way that it always lands another value one less
    # than a power of two.
    #
    # The max insertion idxs form the series:
    #
    #     3, 7, 15, 31, 63, ...
    #
    # The group sizes form the series:
    #
    #     2, 2, 6, 10, 22, 42, 86, ...
    #
    # Therefore, for the input [e0, e1, e2, ...], this method yields
    # [eX, max_idx] pairs like so:
    #
    #     [e1,3] [e0,3] [e3,7] [e2,7] [e9,15] [e8,15] [e7,15] ... [e4,15] ...
    #     |  group 1  | |  group 2  | |              group 3            | ...
    #
    # As an interesting side note: the group sizes series happens to be the
    # difference between adjacent pairs in the Jacobsthal series:
    # https://oeis.org/A001045
    #
    def each_insertion_for(elements_to_insert)
      group_start_idx = 0
      previous_group_size = 0
      power = 1

      while group_start_idx < elements_to_insert.size
        group_size = 2**power - previous_group_size
        group_last_idx = clamp_idx(group_start_idx + group_size - 1, elements_to_insert)
        max_insertion_idx = 2**(power+1) - 1

        group_last_idx.downto(group_start_idx).each do |idx|
          yield [elements_to_insert[idx], max_insertion_idx]
        end

        group_start_idx += group_size
        previous_group_size = group_size
        power += 1
      end
    end

    # Group size determines max_idx, restricting the search range.
    # This is the secret sauce of the whole algorithm.
    def binary_insert_idx(new_element, sorted_elements, max_idx, comparator)
      min_idx = 0
      max_idx = clamp_idx(max_idx, sorted_elements)

      while min_idx != max_idx
        middle_idx = (min_idx + max_idx) / 2
        if greater_than?(new_element, sorted_elements[middle_idx], comparator)
          # must be somewhere after middle_idx (right branch)
          min_idx = middle_idx + 1
        else
          # must be middle_idx or earler (left branch)
          max_idx = middle_idx
        end
      end

      min_idx
    end

    def clamp_idx(idx, array)
      if idx < array.size
        idx
      else
        array.size - 1
      end
    end

    class Pair
      include Comparable

      attr_reader :left, :right

      def self.all_from(elements)
        doublets = elements.each_slice(2).to_a
        stragglers = (elements.size.odd? ? doublets.pop : [])
        pairs = doublets.map { |left, right| new(left, right) }
        [pairs, stragglers]
      end

      def initialize(left, right)
        @left = left
        @right = right
      end

      def to_a
        [left, right]
      end

      def inspect
        "#<Pair #{left.inspect} #{right.inspect}>"
      end

      def to_s
        inspect
      end

      def swap!
        tmp = @left
        @left = @right
        @right = tmp
        nil
      end
    end
end
