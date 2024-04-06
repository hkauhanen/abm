# from https://juliadynamics.github.io/AgentsExampleZoo.jl/dev/examples/social_distancing/#Continuous-space-social-distancing
#
#


using Agents, Random

@agent struct SocialAgent(ContinuousAgent{2, Float64})
    mass::Float64
end

function ball_model(; speed = 0.002)
    space2d = ContinuousSpace((1, 1); spacing = 0.02)
    model = StandardABM(SocialAgent, space2d; agent_step!, properties = Dict(:dt => 1.0),
                        rng = MersenneTwister(42))
    # And add some agents to the model
    for ind in 1:500
        pos = Tuple(rand(abmrng(model), 2))
        vel = sincos(2π * rand(abmrng(model))) .* speed
        add_agent!(pos, model, vel, 1.0)
    end
    return model
end

agent_step!(agent, model) = move_agent!(agent, model, model.dt)

function model_step!(model)
    for (a1, a2) in interacting_pairs(model, 0.012, :nearest)
        elastic_collision!(a1, a2, :mass)
    end
end

model = ball_model()

using CairoMakie

#=
abmvideo(
    "socialdist2.mp4",
    model;
    title = "Billiard-like",
    frames = 50,
    spf = 2,
    framerate = 25,
)
=#

model2 = ball_model()

for id in 1:400
    agent = model2[id]
    agent.mass = Inf
    agent.vel = (0.0, 0.0)
end

#=
abmvideo(
    "socialdist3.mp4",
    model2;
    title = "Billiard-like with stationary agents",
    frames = 50,
    spf = 2,
    framerate = 25,
)
=#

@agent struct PoorSoul(ContinuousAgent{2, Float64})
    mass::Float64
    days_infected::Int  # number of days since is infected
    status::Symbol  # :S, :I or :R
    β::Float64
end

const steps_per_day = 24

using DrWatson: @dict
function sir_initiation(;
    infection_period = 30 * steps_per_day,
    detection_time = 14 * steps_per_day,
    reinfection_probability = 0.05,
    isolated = 0.0, # in percentage
    interaction_radius = 0.012,
    dt = 1.0,
    speed = 0.002,
    death_rate = 0.044, # from website of WHO
    N = 300,
    initial_infected = 5,
    seed = 42,
    βmin = 0.4,
    βmax = 0.8,
)

    properties = (;
        infection_period,
        reinfection_probability,
        detection_time,
        death_rate,
        interaction_radius,
        dt,
    )
    space = ContinuousSpace((1,1); spacing = 0.02)
    model = StandardABM(PoorSoul, space, agent_step! = sir_agent_step!,
                        model_step! = sir_model_step!, properties = properties,
                        rng = MersenneTwister(seed))

    # Add initial individuals
    for ind in 1:N
        pos = Tuple(rand(abmrng(model), 2))
        status = ind ≤ N - initial_infected ? :S : :I
        isisolated = ind ≤ isolated * N
        mass = isisolated ? Inf : 1.0
        vel = isisolated ? (0.0, 0.0) : sincos(2π * rand(abmrng(model))) .* speed

        # very high transmission probability
        # we are modelling close encounters after all
        β = (βmax - βmin) * rand(abmrng(model)) + βmin
        add_agent!(pos, model, vel, mass, 0, status, β)
    end

    return model
end

function transmit!(a1, a2, rp)
    # for transmission, only 1 can have the disease (otherwise nothing happens)
    count(a.status == :I for a in (a1, a2)) ≠ 1 && return
    infected, healthy = a1.status == :I ? (a1, a2) : (a2, a1)

    rand(abmrng(model)) > infected.β && return

    if healthy.status == :R
        rand(abmrng(model)) > rp && return
    end
    healthy.status = :I
end

function sir_model_step!(model)
    r = model.interaction_radius
    for (a1, a2) in interacting_pairs(model, r, :nearest)
        transmit!(a1, a2, model.reinfection_probability)
        elastic_collision!(a1, a2, :mass)
    end
end

function sir_agent_step!(agent, model)
    move_agent!(agent, model, model.dt)
    update!(agent)
    recover_or_die!(agent, model)
end

update!(agent) = agent.status == :I && (agent.days_infected += 1)

function recover_or_die!(agent, model)
    if agent.days_infected ≥ model.infection_period
        if rand(abmrng(model)) ≤ model.death_rate
            remove_agent!(agent, model)
        else
            agent.status = :R
            agent.days_infected = 0
        end
    end
end

sir_model = sir_initiation()

sir_colors(a) = a.status == :S ? "#2b2b33" : a.status == :I ? "#bf2642" : "#338c54"

fig, ax, abmp = abmplot(sir_model; ac = sir_colors)
fig # display figure

sir_model = sir_initiation()

#=
abmvideo(
    "socialdist4.mp4",
    sir_model;
    title = "SIR model",
    frames = 50,
    ac = sir_colors,
    as = 10,
    spf = 1,
    framerate = 20,
)
=#

infected(x) = count(i == :I for i in x)
recovered(x) = count(i == :R for i in x)
adata = [(:status, infected), (:status, recovered)]

r1, r2 = 0.04, 0.33
β1, β2 = 0.5, 0.1
sir_model1 = sir_initiation(reinfection_probability = r1, βmin = β1)
sir_model2 = sir_initiation(reinfection_probability = r2, βmin = β1)
sir_model3 = sir_initiation(reinfection_probability = r1, βmin = β2)

data1, _ = run!(sir_model1, 2000; adata)
data2, _ = run!(sir_model2, 2000; adata)
data3, _ = run!(sir_model3, 2000; adata)

data1[(end-10):end, :]

using CairoMakie

figure = Figure()
ax = figure[1, 1] = Axis(figure; ylabel = "Infected")
l1 = lines!(ax, data1[:, dataname((:status, infected))], color = :orange)
l2 = lines!(ax, data2[:, dataname((:status, infected))], color = :blue)
l3 = lines!(ax, data3[:, dataname((:status, infected))], color = :green)
figure[1, 2][1,1] =
    Legend(figure, [l1, l2, l3], ["r=$r1, beta=$β1", "r=$r2, beta=$β1", "r=$r1, beta=$β2"])
figure

#=
sir_model = sir_initiation(isolated = 0.8)
abmvideo(
    "socialdist5.mp4",
    sir_model;
    title = "Social Distancing",
    frames = 100,
    spf = 2,
    ac = sir_colors,
    framerate = 20,
)
=#

sir_model = sir_initiation(isolated = 0.0)
abmvideo(
    "../videos/epidemic_noisolation.mp4",
    sir_model;
    title = "Epidemic Model without Social Distancing",
    frames = 1000,
    spf = 2,
    ac = sir_colors,
    framerate = 50,
)

sir_model = sir_initiation(isolated = 0.8)
abmvideo(
    "../videos/epidemic_isolation.mp4",
    sir_model;
    title = "Epidemic Model with Social Distancing",
    frames = 1000,
    spf = 2,
    ac = sir_colors,
    framerate = 50,
)



r4 = 0.04
sir_model4 = sir_initiation(reinfection_probability = r4, βmin = β1, isolated = 0.8)

data4, _ = run!(sir_model4, 2000; adata)

l4 = lines!(ax, data4[:, dataname((:status, infected))], color = :red)
figure[1, 2][2,1] = Legend(
    figure,
    [l4],
    ["r=$r4, social distancing"],
)
#figure


