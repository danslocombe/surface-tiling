class Face
  def initialize x, axis1, axis2
    @pos = x
    @a_min = min(axis1, axis2)
    @a_max = max(axis1, axis2)
  end

  def tick translation_matrix
    ret = nil
    @pos = translation_matrix * @pos
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
        shunt_pos
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
        shunt_pos
      end
    when 2
        @a_min = 0
        @a_max = 3

        shunt_pos
    end
    return ret
  end

  private def shunt_pos
    a = @pos.to_a
    @pos = Vector[a[0] - $dirmultx, a[1], a[2], a[3] + $dirmultx]
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
