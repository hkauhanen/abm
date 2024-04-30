module VariationalLearning


using StatsBase

export VariationalLearner, speak, learn!, interact!


mutable struct VariationalLearner
  p::Float64      # prob. of using G1
  gamma::Float64  # learning rate
  P1::Float64     # prob. of L1 \ L2
  P2::Float64     # prob. of L2 \ L1
end


function speak(x::VariationalLearner)
  g = sample(["G1", "G2"], Weights([x.p, 1 - x.p]))

  if g == "G1"
    return sample(["S1", "S12"], Weights([x.P1, 1 - x.P1]))
  else
    return sample(["S2", "S12"], Weights([x.P2, 1 - x.P2]))
  end
end


function learn!(x::VariationalLearner, s::String)
  g = sample(["G1", "G2"], Weights([x.p, 1 - x.p]))

  if g == "G1" && s == "S1"
    x.p = x.p + x.gamma * (1 - x.p)
  elseif g == "G1" && s == "S2"
    x.p = x.p - x.gamma * x.p
  elseif g == "G2" && s == "S2"
    x.p = x.p - x.gamma * x.p
  elseif g == "G2" && s == "S1"
    x.p = x.p + x.gamma * (1 - x.p)
  end

  return x.p
end


function interact!(x::VariationalLearner, y::VariationalLearner)
  s = speak(x)
  learn!(y, s)
end


end
