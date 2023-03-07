module SuperZz

using Stipple
using GenieFramework
using FileIO
using ImageMetadata
using HTTP
using PNGFiles
using Images
#import UUIDs
import Genie.Renderer.Html: HTMLString, normal_element, register_normal_element
using LRUCache
#using Plots, 
using StatsBase
using JSON

# TODO : 

# 1)

# 

# Plugin de test : 
# Sepapez les cannaux 
# Filtre gaussien





# loaded image

include("custom_log.jl")

"""
  Define shortcut for html.div
"""
const mydiv = Genie.Renderer.Html.div

#    permet de d'ulister des balise html non definie dans genis par default
register_normal_element("q__header",context= @__MODULE__ )
register_normal_element("template",context= @__MODULE__ )


include("memory_files.jl")

include("view/zzview.jl")


include("plugin.jl")



# global env structure
struct Env
  user_model

end

"""
create dummy data to delete 
"""
function demo_image()
  @info "load test image"
  path = "/home/bgirard/Téléchargements/P1100119-2.jpg"
  path2 = "/home/bgirard/Téléchargements/test.ome.tif"
  #img = load(path)
  dict = Dict{String,ZzView}("SampleZZ"=>ZzImage(
    image_path=path,
    img_id="SampleZZ",
    img_name="SampleZZ"
  )
  ,
  "ComplexSampleZZ"=>ZzImage(
    image_path=path2,
    img_id="ComplexSampleZZ",
    img_name="ComplexSampleZZ"
  )
  )
  dict["HistSampleZZ"] = ZzPlot(
    img_id="HistSampleZZ",data=histogram(convert(InputImage,dict["SampleZZ"]),NoParam()),
    img_name="HistSampleZZ"
  )

dict["demoRoi"] = ZzRoi(
  img_id="demoRoi",
  img_name="demoRoi",
  rois= Dict(
    "type" => "FeatureCollection",
    "features" => [
      Dict(
        "type"=> "Feature",
        "properties"=> Dict(),
        "geometry"=> Dict(
          "type"=> "Polygon",
          "coordinates"=> [
            [
              [
                618,
                497
              ],
              [
                618,
                611
              ],
              [
                722,
                611
              ],
              [
                722,
                497
              ],
              [
                618,
                497
              ]
            ]
          ]
        )
      ),
      Dict(
        "type"=> "Feature",
        "properties"=> Dict(),
        "geometry"=> Dict(
          "type"=> "Polygon",
          "coordinates"=> [
            [
              [
                268,
                782
              ],
              [
                268,
                904
              ],
              [
                494,
                904
              ],
              [
                494,
                782
              ],
              [
                268,
                782
              ]
            ]
          ]
        )
      )
      ,
      Dict(
        "type"=> "Feature",
        "properties"=> Dict(),
        "geometry"=> Dict(
          "type"=> "Polygon",
          "coordinates"=> [
            [
              [
                722,
                690
              ],
              [
                722,
                950
              ],
              [
                1242,
                950
              ],
              [
                1242,
                690
              ],
              [
                722,
                690
              ]
            ]
          ]
        )
      ),
      Dict(
        "type"=> "Feature",
        "properties"=> Dict(),
        "geometry"=> Dict(
          "type"=> "Polygon",
          "coordinates"=> [
            [
              [
                742,
                218
              ],
              [
                742,
                456
              ],
              [
                1230,
                456
              ],
              [
                1230,
                218
              ],
              [
                742,
                218
              ]
            ]
          ]
        )
      )
    ]
  )

)
return dict
end

function demo_image_viewer()

  [["SampleZZ"],[]]
end


# """
# Main data exachege with main web ui vue.js app 
# """

# @vars Model begin
   
#     leftDrawerOpen::Bool = true
#     rightDrawerOpen::Bool = true

#     image_viewer::Vector{Vector{String}} = demo_image_viewer() # image show is spliter 
 
#     list_image::Dict{String,ZzView} = demo_image() # list of image loaded in memeory 

#     splitter::Int = 100 # spliter proporitn between two image
#     tabs_model::Vector{String} = ["SampleZZ",""] # what iamge are show in each spliter


#     filterimage::String = "" # iamge selected by user
#     filterimagetype::String = "" # iamge selected by user


#     selected_image::Vector{String} = Vector{String}() # iamge selected by user


#     debug::String = "" # show string to debug 

#     files_tree::Vector{Dict{String,Any}} = [Dict("label"=>"/","path"=>"/","lazy"=>true)] # see remote file explorer
#     files_selected::String = ""

# end
mutable struct Model <:  Stipple.ReactiveModel
                  channel__::String
                  _modes::Stipple.LittleDict{Symbol, Any}
                  isready::Stipple.R{Bool}
                  isprocessing::Stipple.R{Bool}
                  leftDrawerOpen::R{Bool}
                  rightDrawerOpen::R{Bool}
                  image_viewer::R{Vector{Vector{String}}}
                  list_image::R{Dict{String, ZzView}}
                  splitter::R{Int}
                  tabs_model::R{Vector{String}}
                  filterimage::R{String}
                  filterimagetype::R{String}
                  selected_image::R{Vector{String}}
                  debug::R{String}
                  files_tree::R{Vector{Dict{String, Any}}}
                  files_selected::R{String}
  end

Model(; channel__ = Stipple.channelfactory(), _modes = Stipple.LittleDict{Symbol, Any}(), isready = false, isprocessing = false, leftDrawerOpen = R{Bool}(true, PUBLIC, false, false, "REPL[7]:3"), rightDrawerOpen = R{Bool}(true, PUBLIC, false, false), image_viewer = R{Vector{Vector{String}}}(demo_image_viewer(), PUBLIC, false, false, "REPL[7]:6"), list_image = R{Dict{String, ZzView}}(demo_image(), PUBLIC, false, false, "REPL[7]:8"), splitter = R{Int}(100, PUBLIC, false, false), tabs_model = R{Vector{String}}(["SampleZZ", ""], PUBLIC, false, false), filterimage = R{String}("", PUBLIC, false, false), filterimagetype = R{String}("", PUBLIC, false, false), selected_image = R{Vector{String}}(Vector{String}(), PUBLIC, false, false), debug = R{String}("", PUBLIC, false, false), files_tree = R{Vector{Dict{String, Any}}}([Dict("label" => "/", "path" => "/", "lazy" => true)], PUBLIC, false, false, "REPL[7]:23"), files_selected = R{String}("", PUBLIC, false, false)) = begin
                  Model(channel__, _modes, isready, isprocessing, leftDrawerOpen, rightDrawerOpen, image_viewer, list_image, splitter, tabs_model, filterimage, filterimagetype, selected_image, debug, files_tree, files_selected)
end
     
delete!.(Ref(Stipple.DEPS), filter((x->begin
                  x isa Type && x <: Model
              end), keys(Stipple.DEPS)))
  #= /home/bgirard/.julia/packages/Stipple/qnyBY/src/stipple/reactivity.jl:349 =#
Stipple.Genie.Router.delete!(Symbol(Stipple.routename(Model)))



include("remote_file_explorer.jl")

include("file_upload.jl")


include("view/custom_method.jl")

include("view/layout.jl")

#custom plugin Pipeline
include("pipeline/pipeline_ui.jl")


# add a test plugiin 
include("test_plugin.jl")


Genie.Assets.add_fileroute(StippleUI.assets_config, "iframe.js", basedir = pwd())

function deps_superzz() :: Vector{String}
  [

    
      Genie.Renderer.Html.script(src = "/stippleui.jl/master/assets/js/iframe.js"),
  ]
end




"""
 Create Model for sync data with vue js
"""
user_model = Stipple.init(Model)

Stipple.deps!("Model", deps_superzz)

route("/") do 
  ui(user_model)
end

"""
Defnien global vaiable for all plugin 
"""
PLUGIN_ENV = Env(user_model)



"""
Start futnion to lauch this module 
"""
function start()
  @genietools
  # to force use caceh
  Genie.Assets.assets_config!([Genie, Stipple, StippleUI, StipplePlotly], host = "https://cdn.statically.io/gh/GenieFramework")
  # using Revise
  # faire fonciotn start and stop 
  Genie.config.websockets_server = true
  #GenieAutoReload.autoreload(joinpath(pwd(),"src"),devonly = false)

  # with_logger(zz_logger) do 
  global_logger(zz_logger)
  up(async=isinteractive()) # or `up(open_browser = true)` to automatically open a browser window/tab when launching the app

  #end
  end

Server.isrunning() || start()

end
