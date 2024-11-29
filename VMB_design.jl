### A Pluto.jl notebook ###
# v0.19.47

using Markdown
using InteractiveUtils

# ╔═╡ b198dcd0-a648-11ef-0ac9-0922626880c2
using Unitful, Unitful.DefaultSymbols

# ╔═╡ 3815d196-81d7-4547-9ea5-3dfda2f6dee5
ρ_copper = 1.68 * 10^−8 * Ω*m

# ╔═╡ b19601be-d8e3-4a38-adf2-62dd8e8c99f8


# ╔═╡ 459ef191-6103-424e-8dca-a6e7ec175732


# ╔═╡ f77595a5-187d-466e-9d33-d92384e57698
ϵ0 = 8.8541878188*10^-12 * A*s / (V*m)

# ╔═╡ 808b11bf-60ac-4735-bb7f-03c30d075f80
ϵpcb =4.5

# ╔═╡ 1a03cc26-83ec-45a9-a031-894ae174fbf4
w = 10mm ; d = 5mm ; l= π * d;h_pcb= 0.34mm

# ╔═╡ 53b00acf-7950-47ad-b82e-bcc0b4167122
h_isolation = 1mm

# ╔═╡ 59c9cb0c-08f8-4ac4-978f-566f8632b99d
Cinner = ϵpcb * ϵ0 * w * l /h_pcb |> pF

# ╔═╡ e3320a5f-c9d2-4e0f-af1f-e6b0e3f4b34c
Couter = ϵpcb * ϵ0 * w * l /h_isolation |> pF

# ╔═╡ b97aa374-c0be-430b-bec6-54a61d9f1f21
Cpos = Couter

# ╔═╡ 0e9ad6c2-b57c-4a13-b5d4-190203320f14
Cneg = Cinner * Couter /(Cinner + Couter)

# ╔═╡ 9eb77648-bbb3-4d58-a73f-9946d2582b94
Rmeasure = 1MΩ

# ╔═╡ 68f5484a-b48d-4170-ba1e-7843c4995665
f_measure = 50Hz

# ╔═╡ 1564f479-36ad-4503-8add-b30ee1d0e5e9
Xc_resistance(C) = 1/(2*π*f_measure * C) |> MΩ

# ╔═╡ b99b28ef-f844-4cee-a7d5-e71ec740c495
Xc_out = Xc_resistance(Couter)

# ╔═╡ ee31c849-e483-4f83-a03b-e0a885294193
Xc_in = Xc_resistance(Cinner)

# ╔═╡ 710c36da-2dde-418d-b0c6-05db515db061
I_measure2 = 250V / (Xc_out + Xc_in + Rmeasure) |> nA

# ╔═╡ 7751f25c-db74-4196-bf8c-d284bcf18f50


# ╔═╡ 975fcf7b-1155-4d16-b5bb-a92a42c3d28a
I_measure = 325V / (Xc_out + Rmeasure) |> nA

# ╔═╡ 9e781f60-2b5f-4538-9faa-e377fa7099b8
Vmeasure = Rmeasure * I_measure |> V

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
Unitful = "1986cc42-f94f-5a68-af5c-568840ba703d"

[compat]
Unitful = "~1.21.0"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.10.4"
manifest_format = "2.0"
project_hash = "b2ca6fc0e82e143bd129203c23f3ad1d89afc9ed"

[[deps.Artifacts]]
uuid = "56f22d72-fd6d-98f1-02f0-08ddc0907c33"

[[deps.CompilerSupportLibraries_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "e66e0078-7015-5450-92f7-15fbd957f2ae"
version = "1.1.1+0"

[[deps.Dates]]
deps = ["Printf"]
uuid = "ade2ca70-3891-5945-98fb-dc099432e06a"

[[deps.Libdl]]
uuid = "8f399da3-3557-5675-b5ff-fb832c97cbdb"

[[deps.LinearAlgebra]]
deps = ["Libdl", "OpenBLAS_jll", "libblastrampoline_jll"]
uuid = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"

[[deps.OpenBLAS_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Libdl"]
uuid = "4536629a-c528-5b80-bd46-f80d51c5b363"
version = "0.3.23+4"

[[deps.Printf]]
deps = ["Unicode"]
uuid = "de0858da-6303-5e67-8744-51eddeeeb8d7"

[[deps.Random]]
deps = ["SHA"]
uuid = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"

[[deps.SHA]]
uuid = "ea8e919c-243c-51af-8825-aaa63cd721ce"
version = "0.7.0"

[[deps.Unicode]]
uuid = "4ec0a83e-493e-50e2-b9ac-8f72acf5a8f5"

[[deps.Unitful]]
deps = ["Dates", "LinearAlgebra", "Random"]
git-tree-sha1 = "d95fe458f26209c66a187b1114df96fd70839efd"
uuid = "1986cc42-f94f-5a68-af5c-568840ba703d"
version = "1.21.0"

    [deps.Unitful.extensions]
    ConstructionBaseUnitfulExt = "ConstructionBase"
    InverseFunctionsUnitfulExt = "InverseFunctions"

    [deps.Unitful.weakdeps]
    ConstructionBase = "187b0558-2788-49d3-abe0-74a17ed4e7c9"
    InverseFunctions = "3587e190-3f89-42d0-90ee-14403ec27112"

[[deps.libblastrampoline_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850b90-86db-534c-a0d3-1478176c7d93"
version = "5.8.0+1"
"""

# ╔═╡ Cell order:
# ╠═b198dcd0-a648-11ef-0ac9-0922626880c2
# ╠═3815d196-81d7-4547-9ea5-3dfda2f6dee5
# ╠═b19601be-d8e3-4a38-adf2-62dd8e8c99f8
# ╠═459ef191-6103-424e-8dca-a6e7ec175732
# ╠═f77595a5-187d-466e-9d33-d92384e57698
# ╠═808b11bf-60ac-4735-bb7f-03c30d075f80
# ╠═1a03cc26-83ec-45a9-a031-894ae174fbf4
# ╠═53b00acf-7950-47ad-b82e-bcc0b4167122
# ╠═59c9cb0c-08f8-4ac4-978f-566f8632b99d
# ╠═e3320a5f-c9d2-4e0f-af1f-e6b0e3f4b34c
# ╠═b97aa374-c0be-430b-bec6-54a61d9f1f21
# ╠═0e9ad6c2-b57c-4a13-b5d4-190203320f14
# ╠═9eb77648-bbb3-4d58-a73f-9946d2582b94
# ╠═68f5484a-b48d-4170-ba1e-7843c4995665
# ╠═1564f479-36ad-4503-8add-b30ee1d0e5e9
# ╠═b99b28ef-f844-4cee-a7d5-e71ec740c495
# ╠═ee31c849-e483-4f83-a03b-e0a885294193
# ╠═710c36da-2dde-418d-b0c6-05db515db061
# ╠═7751f25c-db74-4196-bf8c-d284bcf18f50
# ╠═975fcf7b-1155-4d16-b5bb-a92a42c3d28a
# ╠═9e781f60-2b5f-4538-9faa-e377fa7099b8
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
