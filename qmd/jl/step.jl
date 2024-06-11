function VL_graph_step!(agent, model)
  # neighbours of this agent in the model's network
  nei = neighbors(model.net, agent.id)

  # if agent has neighbours, continue
  if length(nei) > 0
    # choose one of them at random for an interaction
    interlocutor = rand(nei)

    # interact
    interact!(model[interlocutor], agent)
  end
end
