### A Pluto.jl notebook ###
# v0.20.4

using Markdown
using InteractiveUtils

# ╔═╡ a90a4741-efeb-4912-9a03-2df2e2dd115e
using Unitful, Unitful.DefaultSymbols

# ╔═╡ 6d7d4d04-e057-11ee-045f-fd9c50a8e628
md"# Analytical calc"

# ╔═╡ da258640-35c9-4cc5-a168-b4659d4dfe86
md"## Definitions"

# ╔═╡ d87e56b0-16f0-400d-9cf5-f3dc4ea61bea
μ0 = 4*π * 10^-7 *1H/m

# ╔═╡ 43530d66-e713-40df-a881-1d6aed65d4d9
ρ_copper = 1.68 * 10^−8 * Ω*m

# ╔═╡ b967a1a1-72f0-4e69-bec8-5194366c94c7
r_wire= 2.5mm; h_pcb= 0.25mm ; r_pad = 0.35mm/2; spacing = 0.152mm; length = 20mm

# ╔═╡ 7cb3f910-f928-4230-aa04-658271bd59b5
f0 = 150Hz; I0 = 3.0A; f1 = 500Hz; I1 = 0.3A ; f2 = 1kHz; I2 = 0.15A;

# ╔═╡ 500f8845-c680-4d3c-89ef-8d72f3414f1a
f50 = 50Hz; I50 = 50.0A; h=39; f39=50Hz*h

# ╔═╡ 4549359a-c877-4c26-be9b-5e21b41fd1f1
I39=0.15A*15/h

# ╔═╡ 95e0e143-8b1b-4969-a5a7-7ac4f889294c
length_coil = 2*π*r_wire

# ╔═╡ 2666098e-5108-44af-9ebf-44ea3cf8c0e1
md"## Winding Turns Limitation"

# ╔═╡ 1a026491-6780-420b-ac69-b43eca868976
length_coil / (0.375mm)

# ╔═╡ 3f96a506-0774-4c10-afca-95e7ffec2201
r_pad+spacing/2

# ╔═╡ 862a0571-6d95-4b48-b8d6-21089dca0770
N_calc = 2*π / asin((spacing+r_pad+spacing/2) / r_wire)

# ╔═╡ d1ee3cb3-f480-4b20-9f5b-868cb07a4820
N_selected = floor(N_calc)

# ╔═╡ 6472e56c-232c-4c49-a363-4deca6c4bc97
N = 40

# ╔═╡ 0eb25ab4-9f2c-45b1-a0b5-9373efe1cda1
Rw = N * ρ_copper *2 * length / (0.035mm * r_pad) |> Ω

# ╔═╡ 868c3487-fa14-442f-beb2-2e4331fcccb2
md"## Mutual Inductance"

# ╔═╡ b4f64cc4-3d14-477c-8a33-a28b6570f4fd
M = N * μ0 * length * log(1+ h_pcb / r_wire ) / (2*π) |> nH

# ╔═╡ 7a532f93-154d-4ccf-9e09-b655c1694326
L = N^2 * μ0 * length * log(1+ h_pcb / r_wire ) / (2*π) |> μH

# ╔═╡ e1c94940-1f9c-4d9b-bbb1-d85f32227267
1/(2*π*sqrt(L*10pF) ) |> kHz

# ╔═╡ 718b6bfb-4055-4765-94d0-8485a3c6b1f0
R = 600Ω

# ╔═╡ 1a5ec1b5-020b-4800-899e-093339083b11
1/sqrt(L*10pF) * sqrt(R/(R+10Ω)) * (L/R + 10pF * 10Ω ) |> Ω/Ω

# ╔═╡ 217e45a3-b31d-493c-a032-4a221ab90d28
V_induced_peak(f,I) = M * 2 * π * f * I |> μV

# ╔═╡ 49e21374-2ea6-49b2-b0ec-595b89a76f3e
V_Induced_peak_50 = V_induced_peak(f50,I50)

# ╔═╡ 1b13fc04-c285-4e37-aa8b-8ca949b76357
V_Induced_peak_0 = V_induced_peak(f0,I0)

# ╔═╡ 2a41c47c-7472-4938-8931-072ec50bd7ec
V_Induced_peak_1 = V_induced_peak(f1,I1)

# ╔═╡ 8f7b83cb-c773-4227-9687-806d2d125b44
V_Induced_peak_2 = V_induced_peak(f2,I2)

# ╔═╡ 1652564a-f134-4722-847e-648a0c7bb93c
V_Induced_peak_39 = V_induced_peak(f39,I39)

# ╔═╡ e39b7a7c-99c4-4016-af90-12f9bfed6443
md" ## Voltage at ADC"

# ╔═╡ b0507eec-dabf-44ed-9247-1400e7edad8c
Gain_1khz = 10^(60/20)

# ╔═╡ 1819449f-bac5-4f6b-9d5e-5cea327aa323
Gain_10khz = 10^(50/20)

# ╔═╡ 17b57d4f-9a00-4035-bf4d-ba77cd42c5c5
Gain_100khz = 10^(30/20)

# ╔═╡ d9a57092-86e9-4275-92da-51aec58b2f6f
V_Induced_peak_50*Gain_1khz |> mV

# ╔═╡ a12d2fee-eb43-4dbc-8e57-e2b8e3979cf4
V_Induced_peak_0*Gain_1khz |> mV

# ╔═╡ 7a68c452-3073-4929-b947-9267eabfcb45
V_Induced_peak_1*Gain_1khz |> mV

# ╔═╡ 9587233c-10cd-4bbf-bbfa-b2ea318b4ad8
V_Induced_peak_2*Gain_1khz |> mV

# ╔═╡ 36ce73fb-c684-47c8-99b1-e17a14fb0e8c
V_Induced_peak_39*Gain_1khz |> mV

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
Unitful = "1986cc42-f94f-5a68-af5c-568840ba703d"

[compat]
Unitful = "~1.19.0"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.11.2"
manifest_format = "2.0"
project_hash = "c7af93e2569b198d0f2f1604aa17a180c0f3d674"

[[deps.Artifacts]]
uuid = "56f22d72-fd6d-98f1-02f0-08ddc0907c33"
version = "1.11.0"

[[deps.CompilerSupportLibraries_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "e66e0078-7015-5450-92f7-15fbd957f2ae"
version = "1.1.1+0"

[[deps.Dates]]
deps = ["Printf"]
uuid = "ade2ca70-3891-5945-98fb-dc099432e06a"
version = "1.11.0"

[[deps.Libdl]]
uuid = "8f399da3-3557-5675-b5ff-fb832c97cbdb"
version = "1.11.0"

[[deps.LinearAlgebra]]
deps = ["Libdl", "OpenBLAS_jll", "libblastrampoline_jll"]
uuid = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"
version = "1.11.0"

[[deps.OpenBLAS_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Libdl"]
uuid = "4536629a-c528-5b80-bd46-f80d51c5b363"
version = "0.3.27+1"

[[deps.Printf]]
deps = ["Unicode"]
uuid = "de0858da-6303-5e67-8744-51eddeeeb8d7"
version = "1.11.0"

[[deps.Random]]
deps = ["SHA"]
uuid = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"
version = "1.11.0"

[[deps.SHA]]
uuid = "ea8e919c-243c-51af-8825-aaa63cd721ce"
version = "0.7.0"

[[deps.Unicode]]
uuid = "4ec0a83e-493e-50e2-b9ac-8f72acf5a8f5"
version = "1.11.0"

[[deps.Unitful]]
deps = ["Dates", "LinearAlgebra", "Random"]
git-tree-sha1 = "3c793be6df9dd77a0cf49d80984ef9ff996948fa"
uuid = "1986cc42-f94f-5a68-af5c-568840ba703d"
version = "1.19.0"

    [deps.Unitful.extensions]
    ConstructionBaseUnitfulExt = "ConstructionBase"
    InverseFunctionsUnitfulExt = "InverseFunctions"

    [deps.Unitful.weakdeps]
    ConstructionBase = "187b0558-2788-49d3-abe0-74a17ed4e7c9"
    InverseFunctions = "3587e190-3f89-42d0-90ee-14403ec27112"

[[deps.libblastrampoline_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850b90-86db-534c-a0d3-1478176c7d93"
version = "5.11.0+0"
"""

# ╔═╡ Cell order:
# ╠═a90a4741-efeb-4912-9a03-2df2e2dd115e
# ╠═6d7d4d04-e057-11ee-045f-fd9c50a8e628
# ╠═da258640-35c9-4cc5-a168-b4659d4dfe86
# ╠═d87e56b0-16f0-400d-9cf5-f3dc4ea61bea
# ╠═43530d66-e713-40df-a881-1d6aed65d4d9
# ╠═b967a1a1-72f0-4e69-bec8-5194366c94c7
# ╠═7cb3f910-f928-4230-aa04-658271bd59b5
# ╠═500f8845-c680-4d3c-89ef-8d72f3414f1a
# ╠═4549359a-c877-4c26-be9b-5e21b41fd1f1
# ╠═95e0e143-8b1b-4969-a5a7-7ac4f889294c
# ╠═2666098e-5108-44af-9ebf-44ea3cf8c0e1
# ╠═1a026491-6780-420b-ac69-b43eca868976
# ╠═3f96a506-0774-4c10-afca-95e7ffec2201
# ╠═862a0571-6d95-4b48-b8d6-21089dca0770
# ╠═d1ee3cb3-f480-4b20-9f5b-868cb07a4820
# ╠═6472e56c-232c-4c49-a363-4deca6c4bc97
# ╠═0eb25ab4-9f2c-45b1-a0b5-9373efe1cda1
# ╟─868c3487-fa14-442f-beb2-2e4331fcccb2
# ╠═b4f64cc4-3d14-477c-8a33-a28b6570f4fd
# ╠═7a532f93-154d-4ccf-9e09-b655c1694326
# ╠═e1c94940-1f9c-4d9b-bbb1-d85f32227267
# ╠═718b6bfb-4055-4765-94d0-8485a3c6b1f0
# ╠═1a5ec1b5-020b-4800-899e-093339083b11
# ╠═217e45a3-b31d-493c-a032-4a221ab90d28
# ╠═49e21374-2ea6-49b2-b0ec-595b89a76f3e
# ╠═1b13fc04-c285-4e37-aa8b-8ca949b76357
# ╠═2a41c47c-7472-4938-8931-072ec50bd7ec
# ╠═8f7b83cb-c773-4227-9687-806d2d125b44
# ╠═1652564a-f134-4722-847e-648a0c7bb93c
# ╠═e39b7a7c-99c4-4016-af90-12f9bfed6443
# ╠═b0507eec-dabf-44ed-9247-1400e7edad8c
# ╠═1819449f-bac5-4f6b-9d5e-5cea327aa323
# ╠═17b57d4f-9a00-4035-bf4d-ba77cd42c5c5
# ╠═d9a57092-86e9-4275-92da-51aec58b2f6f
# ╠═a12d2fee-eb43-4dbc-8e57-e2b8e3979cf4
# ╠═7a68c452-3073-4929-b947-9267eabfcb45
# ╠═9587233c-10cd-4bbf-bbfa-b2ea318b4ad8
# ╠═36ce73fb-c684-47c8-99b1-e17a14fb0e8c
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
