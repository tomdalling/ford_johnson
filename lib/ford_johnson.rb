require_relative 'ford_johnson/version'

module FordJohnson
  extend self

  def sort(elements, &comparator)
    # Empty arrays and one-element arrays do not need to be sorted.
    return elements if elements.size <= 1

    comparator ||= DEFAULT_COMPARATOR

    # Break the input array into pairs and stragglers. Odd-sized inputs will
    # have a single straggler, and even-sized inputs will have no stragglers.
    pairs = elements.each_slice(2).to_a
    stragglers = (elements.size.odd? ? pairs.pop : [])

    # Sort within each pair.
    pairs.each do |p|
      p.reverse! if greater_than?(p.first, p.last, comparator)
    end

    # Sort between pairs recursively, using the greater (last) value.
    sorted_pairs = sort(pairs) do |left, right|
      comparator.call(left.last, right.last)
    end

    # Split into 'greater' and 'lesser' chains. The greater chain is also known
    # as "S" or the "main" chain. The lesser chain doesn't really have a name---
    # I've seen it called "prep" at least once. Stragglers go on the end of the
    # lesser chain (this is important because it affects insertion order).
    greater_chain = sorted_pairs.map(&:last)
    lesser_chain = sorted_pairs.map(&:first) + stragglers

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
    # increases it in such a way that it always lands on another value that is
    # one less than a power of two.
    #
    # There is a special case for the first insertion. It is guaranteed to be
    # inserted at index zero, and so doesn't require a binary search. The first
    # elemement of both the lesser and greater chains belong to the same pair.
    # Because the greater chain is sorted, and the first element is the higher
    # value of a pair, then the lower value of the pair must be lower than every
    # other element in the greater chain. Returning a max insertion idx of zero
    # short-circuits the whole binary search algorithm.
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
    #     [e0,0] [e2,3] [e1,3] [e4,7] [e3,7] [e10,15] [e9,15] ... [e5,15] ...
    #            |  group 1  | |  group 2  | |          group 3         | ...
    #
    # As an interesting side note: the group sizes series happens to be the
    # difference between adjacent pairs in the Jacobsthal series:
    # https://oeis.org/A001045
    #
    def each_insertion_for(lesser_chain)
      yield [lesser_chain.first, 0]

      group_start_idx = 1 # skip over that first inserted element
      previous_group_size = 0
      power = 1

      while group_start_idx < lesser_chain.size
        group_size = 2**power - previous_group_size
        group_last_idx = [
          group_start_idx + group_size - 1,
          lesser_chain.size - 1,
        ].min # idx must not go off the end of lesser_chain
        max_insertion_idx = 2**(power+1) - 1

        group_last_idx.downto(group_start_idx).each do |idx|
          yield [lesser_chain[idx], max_insertion_idx]
        end

        group_start_idx += group_size
        previous_group_size = group_size
        power += 1
      end
    end

    # the search range is restricted by the max_idx parameter, which is how this
    # algorithm reduces the number of comparisons so well.
    def binary_insert_idx(new_element, sorted_elements, max_idx, comparator)
      min_idx = 0
      max_idx = [max_idx, sorted_elements.size].min # can't go past end of sorted_elements

      while min_idx != max_idx
        middle_idx = (min_idx + max_idx) / 2
        if greater_than?(new_element, sorted_elements[middle_idx], comparator)
          # must be somewhere after middle_idx (right branch)
          min_idx = middle_idx + 1
        else
          # must be middle_idx or earlier (left branch)
          max_idx = middle_idx
        end
      end

      min_idx
    end
end
