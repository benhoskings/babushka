module Babushka
  class Spell

    # Return a new array containing the terms from this array that were
    # determined to be 'similar to' +string+. A string is considered to
    # be similar to another if its Levenshtein distance is less than
    # either the string's length minus one, or one fifth is length plus
    # two, whichever is less.
    #
    #     word length  1  2  3  4  5  6  7  8  9  10  11  12  13  14  15  …
    #   typos allowed  0  0  1  2  3  3  3  3  3   4   4   4   4   4   5  …
    #
    # This means that:
    #   - a little over one fifth of strings longer than 4 characters can be misspelt;
    #   - strings 3 or 4 characters long can have 1 or 2 misspelt characters respectively;
    #   - strings 1 or 2 characters long must be spelt correctly.
    def self.for(string, choices:)
      choices.map {|term|
        [term, Babushka::Levenshtein.distance(term, string)]
      }.select {|(i, similarity)|
        similarity <= [i.length - 2, (i.length / 5) + 2].min
      }.sort_by {|(_, similarity)|
        similarity
      }.map {|(i, _)|
        i
      }
    end

  end
end
