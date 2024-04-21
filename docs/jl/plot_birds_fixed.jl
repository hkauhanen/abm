# a Plots.jl recipe that can be used to plot the positions and directions
# of a population of Bird objects
#
# Bug-fixed version.
#
# -hk 2024

import Plots

@recipe function f(p::Array{Bird})
  # make sure plot has square aspect ratio
  size := (300, 300)

  # get maximum positions so that we can scale the arrows to plot size
  x_extent = abs(extrema([b.x for b in p])[2] - extrema([b.x for b in p])[1])
  y_extent = abs(extrema([b.y for b in p])[2] - extrema([b.y for b in p])[1])

  # set arrow's length to be one tenth of of average "extent"
  delta = 0.1*(x_extent + y_extent)/2

  # loop through population
  for b in p
    # plot Bird directions as little arrows
    @series begin
      legend := false
      seriestype := :line
      linecolor := :black

      # length of direction vector
      L = sqrt(b.dir_x^2 + b.dir_y^2)

      # amounts to be added to position to fly
      add_x = delta*b.dir_x/L
      add_y = delta*b.dir_y/L

      # the following conditional logic is needed to get the arrows
      # going in the right directions
      if add_x < 0 && add_y < 0
        arrow := arrow(:tail)
      elseif add_x < 0 && add_y >= 0
        arrow := arrow(:tail)
      else
        arrow := arrow(:head)
      end

      ([b.x, b.x + add_x], [b.y, b.y + add_y])
    end

    # plot Bird positions as points
    @series begin
      seriestype := :scatter
      legend := false
      ([b.x], [b.y])
    end
  end
end

