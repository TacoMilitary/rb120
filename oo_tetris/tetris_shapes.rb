module TetrisShapes
  ROTATE_CENTER = :rotate_center
  LIMB_DATA = :limb_data

  FILLED_CELL_PATTERN = 'N'
  EMPTY_CELL_PATTERN = ' '

  # Golomb names taken from
  # "https://quuxplusone.github.io/blog/2025/04/19/tetromino-names/"
  #
  # :rotate_center is the coordinates of the 
  # limb that the shape rotates around. if this is not provided
  # it is assumed that the shape cannot rotate

    SHAPES =
      [
        # Square tetromino
        { LIMB_DATA => "NN\nNN" },

        # T-tetromino
        { LIMB_DATA => " N\nNNN", ROTATE_CENTER => { y: 1, x: 1 } },

        # Straight tetromino
        { LIMB_DATA => "NNNN", ROTATE_CENTER => { y: 0, x: 0 } },

        # Skrew tetromino green
        { LIMB_DATA => " NN\nNN", ROTATE_CENTER => { y: 1, x: 1 } },

        # Skrew tetromino red
        { LIMB_DATA => "NN\n NN", ROTATE_CENTER => { y: 1, x: 1 } },

        # L-tetromino blue
        { LIMB_DATA => "N\nNNN", ROTATE_CENTER => { y: 1, x: 0 } },

        # L-tetromino orange
        { LIMB_DATA => "  N\nNNN", ROTATE_CENTER => { y: 1, x: 2 } }
      ].freeze

  def self.random_shape
    Shape.new(SHAPES.sample)
  end
end
