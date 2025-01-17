### A Pluto.jl notebook ###
# v0.19.12

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    quote
        local iv = try Base.loaded_modules[Base.PkgId(Base.UUID("6e696c72-6542-2067-7265-42206c756150"), "AbstractPlutoDingetjes")].Bonds.initial_value catch; b -> missing; end
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : iv(el)
        el
    end
end

# ╔═╡ 516fb872-3f9f-11ed-3ae3-f7e56bdfe688
begin
	import Pkg
	Pkg.add("Plots")
	Pkg.add("Colors")
	Pkg.add("Images")
	Pkg.add("Measures")
	Pkg.add("DataFrames")
	Pkg.add("Statistics")
	Pkg.add("RecursiveArrayTools")
	Pkg.add("LsqFit")
	Pkg.develop(url="https://github.com/JuliaNeuroscience/NIfTI.jl")
	using Plots, NIfTI, Statistics, Colors, Images, Measures
	using DataFrames, LsqFit
	using RecursiveArrayTools
end

# ╔═╡ dea1ba1e-d65f-496d-99e2-5ff2772718d1
function gcircle(x,y)
	return -exp(-(1-sqrt(x^2+y^2))^2/0.02)
end

# ╔═╡ 76e8ea2d-14b7-4291-98cd-0977ade82a87
x_range = -4:0.1:4.0

# ╔═╡ d338e459-e87e-4321-88df-3649bb23832b
y_range = -4:0.1:4.0

# ╔═╡ 150e1531-c18d-4d9f-acf0-a800e3c62f42
begin
	heatmap(x_range,y_range,gcircle,aspect_ratio=1)
	#savefig("circle.png")
end

# ╔═╡ 26623943-a072-451e-b76a-68f7d24c9d92
function gellipse(x,y,x0,y0,rx,ry,θ,A,σ)
	dx = x - x0
	dy = y - y0
	ct = cos(θ)
	st = sin(θ)
	return -A*exp(-(1-sqrt((dx*ct+dy*st)^2/rx^2+(dx*st-dy*ct)^2/ry^2))^2/σ^2)
end

# ╔═╡ 141a2704-2aac-4eb6-9158-9f36af7e037c
begin
	heatmap(x_range,y_range,
			(x,y)->gellipse(x,y,0.0,0.0,1.0,2.0,π/3,1.0,0.05),aspect_ratio=1)
	#savefig("ellipse.png")
end

# ╔═╡ 6a0a68ce-d0c5-4121-ba6d-92827a79bd36
Red(x) = RGB(x,0,0)

# ╔═╡ 2b14019b-d81b-43c8-9f4d-e6eae6fc338a
phantom = niread("/Users/hstrey/Desktop/Phantom_talk/Phantom dataset/epi/epi.nii")

# ╔═╡ 1da66576-532e-42e7-b724-31171ecce3bd
phantom_ok = phantom[2:end,:,:,1:200]

# ╔═╡ bf538333-7ad8-417e-a998-0c6f4007d438
phantom_static = niread("b_150_3.nii")

# ╔═╡ a815b01b-2ff0-47fe-9a82-5906d69fdb03
md"""
pick slice and time
$(@bind pick_slice html"<input type=range min=1 max=28 value=1>")slice
"""

# ╔═╡ 21019261-f46a-49ea-a477-9383df80ea18
size(phantom_static[:,:,pick_slice])

# ╔═╡ 7c8808c3-97e4-4139-ba9b-cf38d4b63636
md"""
Estimate center
$(@bind h html"<input type=range min=1 max=84 value=42>")horz
$(@bind v html"<input type=range min=1 max=84 value=42>")vert
$(@bind r html"<input type=range min=1 max=40 value=10>")radius
"""

# ╔═╡ 7a130413-59cc-434c-9835-16df8ec239c2
(v,h,r)

# ╔═╡ bec5704f-40f8-4e1a-b197-8b5f53a75616
begin
	plot(Gray.(phantom_static[:,:,pick_slice] ./ findmax(phantom_static[:,:,pick_slice])[1]),
		aspect_ratio=1.0,
		axis = nothing,
		framestyle=:none,
		title="slice $pick_slice",
		size=(400,450))
	hline!([h],color=:red,label="horz $h")
	vline!([v],color=:green,label="vert $v")
	phi = 0:0.01:2π
	circle_x = r .* cos.(phi) .+ v
	circle_y = r .* sin.(phi) .+ h
	plot!(circle_x, circle_y, label="radius $r")
end

# ╔═╡ f5e13e16-3181-433a-874d-725c4a8cc989
# we need to extract pixels that are half way to the outer and inner ring
begin
	x_list = []
	y_list = []
	z_list = []
	ps = size(phantom_static[:,:,pick_slice])
	for i in 1:ps[1]
		for j in 1:ps[2]
			if (i-h)^2+(j-v)^2>(r^2/4) && (i-h)^2+(j-v)^2<(1.5*r)^2
				push!(x_list,i)
				push!(y_list,j)
				push!(z_list,phantom_static[i,j,pick_slice])
			end
		end
	end
end

# ╔═╡ 426cf44d-0b4f-450f-9fa7-1c2182dcb0aa
begin
	mask = zeros(size(phantom_static[:,:,pick_slice]))
	for (i,j) in zip(x_list,y_list)
		mask[i,j]=1.0
	end
end

# ╔═╡ 89c39b45-2e15-4706-8506-4ad5d50078a0
begin
	plot(Gray.(phantom_static[:,:,pick_slice] .* mask)./ findmax(phantom_static[:,:,pick_slice])[1],
	aspect_ratio=1.0,
		axis = nothing,
		framestyle=:none,
		title="first ok slice",
		size=(400,450))
	hline!([h],color=:red,label="horz $h")
	vline!([v],color=:green,label="vert $v")
	plot!(circle_x, circle_y, label="radius $r")
end

# ╔═╡ fde99231-c059-4753-a4f7-b79865cca411
plot(phantom_static[h,:,pick_slice])

# ╔═╡ 4d85c9d4-5188-4297-950d-b797996d2440
phantom_static[h,v,pick_slice]

# ╔═╡ 4843e623-1498-4d76-8576-f6e88493fc62
function gaussellipse(xy,p)
	x0,y0,rx,ry,θ,A,bg,σ = p #unpack parameters
	x = xy[:,1]
	y = xy[:,2]
	dx = x .- x0
	dy = y .- y0
	ct = cos(θ)
	st = sin(θ)
	return bg .- A * exp.( -(1 .-sqrt.(( dx .* ct .+ dy .* st ).^2/rx^2+(dx .* st .- dy .* ct).^2/ry^2)).^2/σ^2)
end

# ╔═╡ fbd83fde-fd06-4dd1-bf8c-2e2eeff491c1
function gaellipse(x,y,p)
	x0,y0,rx,ry,θ,A,bg,σ = p #unpack parameters
	dx = x - x0
	dy = y - y0
	ct = cos(θ)
	st = sin(θ)
	return bg - A * exp( -(1 -sqrt(( dx * ct + dy * st )^2/rx^2+(dx * st - dy * ct)^2/ry^2))^2/σ^2)
end

# ╔═╡ 1255746f-4d9a-4a7f-af18-99b188fc7acf
xy = hcat(x_list,y_list)

# ╔═╡ d094e7c9-cd3b-40bb-b787-0c930b67962d
p0 = Float64.([h, v, r, r, 0, phantom_static[h,v,pick_slice]-400, phantom_static[h,v,pick_slice], 0.1])

# ╔═╡ da07ba0b-1f2c-49d0-8dd1-e670e890f487
fit = curve_fit(gaussellipse, xy, z_list, p0)

# ╔═╡ b071db02-337c-4137-ac62-b9851d9252a0
x_r = 0:0.1:85

# ╔═╡ 79af4b39-2d98-4e48-86d1-1ffd45215b4c
y_r = 0:0.1:85

# ╔═╡ 2e936a60-fc70-4e21-bb1e-e953e41165da
heatmap(x_r,y_r,(x,y)->gaellipse(x,y,fit.param),aspect_ratio=1)

# ╔═╡ Cell order:
# ╠═516fb872-3f9f-11ed-3ae3-f7e56bdfe688
# ╠═dea1ba1e-d65f-496d-99e2-5ff2772718d1
# ╠═76e8ea2d-14b7-4291-98cd-0977ade82a87
# ╠═d338e459-e87e-4321-88df-3649bb23832b
# ╠═150e1531-c18d-4d9f-acf0-a800e3c62f42
# ╠═26623943-a072-451e-b76a-68f7d24c9d92
# ╠═141a2704-2aac-4eb6-9158-9f36af7e037c
# ╠═6a0a68ce-d0c5-4121-ba6d-92827a79bd36
# ╠═2b14019b-d81b-43c8-9f4d-e6eae6fc338a
# ╠═1da66576-532e-42e7-b724-31171ecce3bd
# ╠═bf538333-7ad8-417e-a998-0c6f4007d438
# ╠═7a130413-59cc-434c-9835-16df8ec239c2
# ╟─a815b01b-2ff0-47fe-9a82-5906d69fdb03
# ╠═bec5704f-40f8-4e1a-b197-8b5f53a75616
# ╠═21019261-f46a-49ea-a477-9383df80ea18
# ╠═f5e13e16-3181-433a-874d-725c4a8cc989
# ╠═426cf44d-0b4f-450f-9fa7-1c2182dcb0aa
# ╟─7c8808c3-97e4-4139-ba9b-cf38d4b63636
# ╠═89c39b45-2e15-4706-8506-4ad5d50078a0
# ╠═fde99231-c059-4753-a4f7-b79865cca411
# ╠═4d85c9d4-5188-4297-950d-b797996d2440
# ╠═4843e623-1498-4d76-8576-f6e88493fc62
# ╠═fbd83fde-fd06-4dd1-bf8c-2e2eeff491c1
# ╠═1255746f-4d9a-4a7f-af18-99b188fc7acf
# ╠═d094e7c9-cd3b-40bb-b787-0c930b67962d
# ╠═da07ba0b-1f2c-49d0-8dd1-e670e890f487
# ╠═b071db02-337c-4137-ac62-b9851d9252a0
# ╠═79af4b39-2d98-4e48-86d1-1ffd45215b4c
# ╠═2e936a60-fc70-4e21-bb1e-e953e41165da
