# From here
# http://www.mathematicians.org.uk/eoh/files/Harriss_ANGASRP.pdf

require 'chunky_png'
require 'matrix'

all_faces = []

def min(*values)
 values.min
end

def max(*values)
 values.max
end

A = Matrix[[0, 0, 0, -1],
           [1, 0, 0, 0],
           [0, 1, 0, 0],
           [0, 0, 1, 1]]


$dirmultx = 1
$dirmulty = 1
$global_xo = 0
$global_yo = 0

hue = 345#rand(360)
h1 = hue
h2 = (hue + 360/2) % 360
COLORS = [
  ChunkyPNG::Color.from_hsv(0, 0, 1),
  ChunkyPNG::Color.from_hsv(0, 0.0, 1),
  ChunkyPNG::Color.from_hsv(h1, 0.8, 1),
  ChunkyPNG::Color.from_hsv(h2, 0.8, 1),
  ChunkyPNG::Color.from_hsv(h1, 0.75, 0.6),
  ChunkyPNG::Color.from_hsv(h2, 0.75, 0.6)
  ]

class Face
  def initialize(x, axis1, axis2, parent, children)
    @pos = x
    @a_min = min(axis1, axis2)
    @a_max = max(axis1, axis2)
    # Starting at right anti clockwise
  end

  def tick
    ret = nil
    @pos = A * @pos
    case @a_min
    when 0
      case @a_max
      when 1
        @a_min = 1
        @a_max = 2
      when 2
        @a_min = 1
        @a_max = 3
      when 3
        @a_min = 0
        @a_max = 1

        ret = Face.new(@pos.clone, 1, 3, @parent, [self])

        a = @pos.to_a
        @pos = Vector[a[0] - $dirmultx, a[1], a[2], a[3] + $dirmultx]
      end
    when 1
      case @a_max
      when 2
        @a_min = 2
        @a_max = 3
      when 3
        @a_min = 0
        @a_max = 2

        ret = Face.new(@pos.clone, 2, 3, @parent, [self])

        a = @pos.to_a
        @pos = Vector[a[0] - $dirmultx, a[1], a[2], a[3] + $dirmultx]
      end
    when 2
        @a_min = 0
        @a_max = 3

        a = @pos.to_a
        @pos = Vector[a[0] - $dirmultx, a[1], a[2], a[3] + $dirmultx]
    end
    return ret
  end

  def pos
    @pos
  end

  def min_axis
    @a_min
  end
  def max_axis
    @a_max
  end
end

all_faces << Face.new(Vector[0, 0, 0, 0], 2, 3, nil, [])


$image_width = 2048
$image_height = 2048
$ox = $image_width/2
$oy = $image_height/2
$scale = -42

#e_1 = 1
#e_2 = lambda
#e_3 = lamdba^2
#e_3 = lamdba^3
#where lambda = 1.01891 + 0.602565i
$canonical_x = [1, 1.01891, 0.675093, -0.0520420]
$canonical_y = [0, 0.602565, 1.22792,  1.65793]

def min_max_to_i min, max
  return max - 1 if min == 0
  return 1 + max if min == 1
  return 5
end

def to_image_space p
  {x: ($ox +$global_xo -$scale * (p[0] * $canonical_x[0] + p[1] * $canonical_x[1] + 
               p[2] * $canonical_x[2] + p[3] * $canonical_x[3])),
   y: ($oy + $global_yo + $scale * (p[0] * $canonical_y[0] + p[1] * $canonical_y[1] + 
               p[2] * $canonical_y[2] + p[3] * $canonical_y[3]))};
end

ticks = 30
for i in 1 .. ticks
  print "\nTick #{i}\n"
  new_list = []
  all_faces.each do |face|
    new_list << face
    ret = face.tick
    new_list << ret unless ret.nil?
  end
  all_faces = new_list

  $global_xo = 0
  $global_yo = 0
  p = to_image_space(all_faces[0].pos.to_a)
  $global_xo = $ox - p[:x]
  $global_yo = $oy - p[:y]

  # Draw
  image = ChunkyPNG::Image.new($image_width, $image_height, ChunkyPNG::Color::TRANSPARENT)
  #image[0, 0] = ChunkyPNG::Color.rgba(255, 0,0, 128)

  all_faces.each do |face|
    p1 = to_image_space (face.pos.to_a)

    p2_m = face.pos.to_a
    p2_m[face.min_axis] += 1
    p2 = to_image_space(p2_m) 

    p3_m = face.pos.to_a
    p3_m[face.max_axis] += 1
    p3 = to_image_space(p3_m) 

    p4_m = face.pos.to_a
    p4_m[face.min_axis] += 1
    p4_m[face.max_axis] += 1
    p4 = to_image_space(p4_m) 


    points = ChunkyPNG::Vector.new([p1, p2, p4, p3])
    color = COLORS[min_max_to_i face.min_axis, face.max_axis]
    image.polygon(points, ChunkyPNG::Color::TRANSPARENT, color) 
  end
  image.save("out/test_tick_#{i}.png", :interlace => false)
end
