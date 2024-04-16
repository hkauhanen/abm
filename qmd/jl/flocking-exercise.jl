mutable struct Bird
	x::Float64
	y::Float64
	dir_x::Float64
	dir_y::Float64
end

function fly!(b::Bird, delta::Float64)
	b.x = b.x + delta*b.dir_x
	b.y = b.y + delta*b.dir_y
end




