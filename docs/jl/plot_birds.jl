# a Plots.jl recipe that can be used to plot the positions and directions
# of a population of Bird objects
#
# -hk 2024


@recipe function f(p::Array{Bird})
  # used to scale the length of arrows (see below)
  delta = 0.1

  # make sure plot has square aspect ratio
  size := (300, 300)

  # plot Bird directions as little arrows
  for b in p
    @series begin
      legend := false
      seriestype := :line
      linecolor := :black
      arrow := true
      L = sqrt(b.dir_x^2 + b.dir_y^2)
      ([b.x, b.x + delta*b.dir_x/L], [b.y, b.y + delta*b.dir_y/L])
    end

    # plot Bird positions as points
    @series begin
      seriestype := :scatter
      legend := false
      ([b.x], [b.y])
    end
  end
end

