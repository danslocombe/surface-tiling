# Example image

require './tiling'

TilerBuilder.new('../example_image.png').set_hue(345).set_image_size(1024, 1024).set_scale(46).set_ticks(24).build
