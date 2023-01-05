using SuperZz
using Documenter

DocMeta.setdocmeta!(SuperZz, :DocTestSetup, :(using SuperZz); recursive=true)

makedocs(;
    modules=[SuperZz],
    authors="Arnold",
    repo="https://github.com/a-r-n-o-l-d/SuperZz.jl/blob/{commit}{path}#{line}",
    sitename="SuperZz.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://a-r-n-o-l-d.github.io/SuperZz.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/a-r-n-o-l-d/SuperZz.jl",
    devbranch="main",
)
