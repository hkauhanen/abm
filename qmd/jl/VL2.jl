module VL

# Agents.jl functionality
using Agents

# we need this package for the sample() function
using StatsBase

# we export the following types and functions
export VariationalLearner
export SimpleVL
export NetworkVL
export GridVL
export speak
export learn!
export interact!
export VL_step!


# abstract type
abstract type VariationalLearner <: AbstractAgent end

# variational learner type on a 2D grid
@agent struct GridVL(GridAgent{2}) <: VariationalLearner
  p::Float64      # prob. of using G1
  gamma::Float64  # learning rate
  P1::Float64     # prob. of L1 \ L2
  P2::Float64     # prob. of L2 \ L1
end

@agent struct NetworkVL(GraphAgent) <: VariationalLearner
  p::Float64      # prob. of using G1
  gamma::Float64  # learning rate
  P1::Float64     # prob. of L1 \ L2
  P2::Float64     # prob. of L2 \ L1
end

# "simple" variational learner in unstructured population
mutable struct SimpleVL <: VariationalLearner
  p::Float64      # prob. of using G1
  gamma::Float64  # learning rate
  P1::Float64     # prob. of L1 \ L2
  P2::Float64     # prob. of L2 \ L1
end

# makes variational learner x utter a string
function speak(x::VariationalLearner)
  g = sample(["G1", "G2"], Weights([x.p, 1 - x.p]))

  if g == "G1"
    return sample(["S1", "S12"], Weights([x.P1, 1 - x.P1]))
  else
    return sample(["S2", "S12"], Weights([x.P2, 1 - x.P2]))
  end
end

# makes variational learner x learn from input string s
function learn!(x::VariationalLearner, s::String)
  g = sample(["G1", "G2"], Weights([x.p, 1 - x.p]))

  if g == "G1" && s != "S2"
    x.p = x.p + x.gamma * (1 - x.p)
  elseif g == "G1" && s == "S2"
    x.p = x.p - x.gamma * x.p
  elseif g == "G2" && s != "S1"
    x.p = x.p - x.gamma * x.p
  elseif g == "G2" && s == "S1"
    x.p = x.p + x.gamma * (1 - x.p)
  end

  return x.p
end

# makes two variational learners interact, with one speaking
# and the other one learning
function interact!(x::VariationalLearner, y::VariationalLearner)
  s = speak(x)
  learn!(y, s)
end

# steps a model
function VL_step!(agent::VariationalLearner, model)
  interlocutor = random_nearby_agent(agent, model)
  interact!(interlocutor, agent)
end

# steps a model; version for NetworkVLs
function VL_step!(agent::NetworkVL, model)
  try
    interlocutor = random_nearby_agent(agent, model)
    interact!(interlocutor, agent)
  catch
  end
end


end   # this closes the module
