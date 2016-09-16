# From here
# http://www.mathematicians.org.uk/eoh/files/Harriss_ANGASRP.pdf

require 'chunky_png'
require 'matrix'
require 'digest'



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

def min_max_to_i min, max
  return max - 1 if min == 0
  return 1 + max if min == 1
  return 5
end
$dirmultx = 1
$dirmulty = 1

class Face
  def initialize x, axis1, axis2
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

        ret = Face.new(@pos.clone, 1, 3)

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

        ret = Face.new(@pos.clone, 2, 3)

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

class TilerBuilder

  def initialize filename
    @hue = 345#rand(360)
    @image_width = 256
    @image_height = 256
    @ox = @image_width/2
    @oy = @image_height/2
    @scale = -24
    @ticks = 22
    @filename = filename
    @sat_major = 1
    @sat_minor = 0.8
    @projection_lambda = Complex(1.01891, 0.602565)
    self
  end
  
  def set_scale scale
    @scale = scale
    self
  end

  def set_hue hue
    @hue = hue
    self
  end

  def set_sat_major s
    @sat_major = s
    self
  end

  def set_sat_minor s
    @sat_minor = s
    self
  end

  def set_image_size width, height
    @image_width = width
    @image_height = height
    self
  end

  def set_ticks ticks
    @ticks = ticks
    self
  end

  def set_projection_lambda x, y
    @projection_lambda = Complex(x, y)
    self
  end

  def build
    t = Tiler.new(@image_width, @image_height, @scale, @hue, @sat_major, 
                  @sat_minor, @projection_lambda)
    t.tile(@ticks, @filename)
  end
end


class Tiler
  def initialize image_width, image_height, scale, hue, sat_major, sat_minor, projection_lambda
    @h1 = hue
    @h2 = (hue + 360/2) % 360

    @colors = [
      ChunkyPNG::Color.from_hsv(0, 0, 1),
      ChunkyPNG::Color.from_hsv(0, 0.0, 1),
      ChunkyPNG::Color.from_hsv(@h1, sat_major, 1),
      ChunkyPNG::Color.from_hsv(@h2, sat_major, 1),
      ChunkyPNG::Color.from_hsv(@h1, sat_minor, 0.6),
      ChunkyPNG::Color.from_hsv(@h2, sat_minor, 0.6)
    ]


    @image_width = image_width
    @image_height = image_height
    @ox = @image_width/2
    @oy = @image_height/2
    @scale = scale

    @canonical_x = []
    @canonical_y = []
    for i in 0..3 do
      c = projection_lambda ** i
      @canonical_x << c.real
      @canonical_y << c.imaginary
    end
    @all_faces = [Face.new(Vector[0, 0, 0, 0], 2, 3)]
  end



  def to_image_space p
    {x: (@ox + @global_xo -@scale * (p[0] * @canonical_x[0] + p[1] * @canonical_x[1] + 
                 p[2] * @canonical_x[2] + p[3] * @canonical_x[3])),
     y: (@oy + @global_yo + @scale * (p[0] * @canonical_y[0] + p[1] * @canonical_y[1] + 
                 p[2] * @canonical_y[2] + p[3] * @canonical_y[3]))};
  end

  def tile ticks, filename
    for i in 1 .. ticks
      new_list = []
      @all_faces.each do |face|
        new_list << face
        ret = face.tick
        new_list << ret unless ret.nil?
      end
      @all_faces = new_list

      @global_xo = 0
      @global_yo = 0
      p = to_image_space(@all_faces[0].pos.to_a)
      @global_xo = @ox - p[:x]
      @global_yo = @oy - p[:y]

    end
    # Draw
    image = ChunkyPNG::Image.new(@image_width, @image_height, ChunkyPNG::Color::TRANSPARENT)
    #image[0, 0] = ChunkyPNG::Color.rgba(255, 0,0, 128)

    puts "Drawing image"
    @all_faces.each_with_index do |face, i|
      print "Face #{i}\r"

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
      color = @colors[min_max_to_i face.min_axis, face.max_axis]
      image.polygon(points, ChunkyPNG::Color::TRANSPARENT, color) 
      #image.polygon(points, ChunkyPNG::Color.from_hsv(0, 0, 0),ChunkyPNG::Color.from_hsv(0, 0, 1))
    end
    puts "\nSaving image to #{filename}"
    image.save(filename, :interlace => false)
  end
  
end
def fromMD5 filename, hash
    r = Hashrander.new(hash)
    hue = r.get_rand 3, 360
    s1 = 0.5 + (r.get_rand 2, 0.5)
    s2 = 0.5 + (r.get_rand 2, 0.5 * s1)

    p_x = 0.5 + (r.get_rand 2, 1.15)
    p_y = 0.5 + (r.get_rand 2, 1.15)

    TilerBuilder.new(filename).set_hue(hue).set_sat_major(s1).set_sat_minor(s2).set_projection_lambda(p_x, p_y).build
end

class Hashrander
  def initialize hash
    @hash_i = 0
    @hash = hash
  end

  def get_rand sample_size, max
    i1 = @hash_i % @hash.length

    hash_str = @hash[i1, sample_size]

    # Check if wrap over length
    rem = i1 + sample_size - @hash.length
    if rem > 0
      hash_str << @hash[0, rem]
    end

    @hash_i += sample_size

    max * hash_str.hex/(16**sample_size)
  end
end


[
'dan@3rdrock.uk', 
'elliot@3rdrock.uk', 
'pranav@3rdrock.uk', 
'louis@3rdrock.uk',
'aan@3rdrock.uk', 
'alliot@3rdrock.uk', 
'aranav@3rdrock.uk', 
'aouis@3rdrock.uk'
].each do |input|

  md5 = Digest::MD5.new
  md5 << input
  hash = md5.hexdigest

  fromMD5 "out/hash/hash_#{hash}.png", hash
end
