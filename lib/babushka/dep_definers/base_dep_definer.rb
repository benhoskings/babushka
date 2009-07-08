module Babushka
  class BaseDepDefiner < DepDefiner

    accepts_hash_for :requires
    accepts_hash_for :asks_for
    accepts_block_for :setup
    accepts_block_for :met?
    accepts_block_for :meet
    accepts_block_for :before
    accepts_block_for :after

  end
end
