module SuperZz
using Genie, Genie.Renderer.Html # some app deps
using GenieAutoReload
const mydiv = Genie.Renderer.Html.div
using Stipple, StippleUI
using Images, FileIO
import UUIDs
import Genie.Renderer.Html: HTMLString, normal_element, register_normal_element

include("custom_log.jl")
include("html_param.jl")
include("pipeline.jl")

register_normal_element("q__header",context= @__MODULE__ )

#register_normal_element("template",context= @__MODULE__ )







# Write your package code here.

# function plugin_loading()
#     using FromFile: @from
#     plugins = []
#     map(requested_plugins) do plugin_path
#         plugin_name = splitext(splitdir(plugin_path)[2])[1]
#         plugin = Symbol(plugin_name)
#         @eval @from $plugin_path import $plugin
#         @eval $plugin.activate()
#         push!(plugins, plugin)
#     end
# end



const IMG_PATH = "/dev/shm/currentZz.png"
const UPLOAD_PATH = "/dev/shm/"

css() = style("""

.active-link
{
  color: white
  background: #F2C037
}


""")
  


# loaded image
Stipple.@kwdef mutable struct ZzImage

  img_id::String  = ""
  image_path::String = ""

  # TODO 

end


function demo_image()
  @info "load test image"
  path = "/home/bgirard/Téléchargements/P1100119-2.jpg"
  path2 = "/home/bgirard/Téléchargements/mitosis.tif"
  #img = load(path)
  #save(IMG_PATH,img)
  Dict("SampleZZ"=>ZzImage(
    image_path=path,
    img_id="SampleZZ",
  ),
  "ComplexSampleZZ"=>ZzImage(
    image_path=path2,
    img_id="ComplexSampleZZ",
  )
  )
end

function demo_image_viewer()

  [["SampleZZ"],[]]
end


PipelineStructGenerator()

@vars Model begin
  
    leftDrawerOpen::R{Bool} = true

    image_viewer::R{Vector{Vector{String}}} = demo_image_viewer()

    list_image::R{Dict{String,ZzImage}} = demo_image()

    splitter::R{Int} = 100
    tabs_model::R{Vector{String}} = ["SampleZZ",""]


    selected_image::R{String} = ""

    debug::R{String} = ""

    @mixin PipelineFlat
end





include("html_param.jl")



function html_param_node(user_model,pipeline,node)
  process=node.process
  @info "generate html for $process"
  paramtype = process.Param
  list = []

  for (field_name,field_type) in zip(fieldnames(paramtype),fieldtypes(paramtype))
       @info field_name
       if startswith(string(field_name),"channel") || startswith(string(field_name),"_") || startswith(string(field_name),"isready")  || startswith(string(field_name),"isprocessing")
         continue
       end
       push!(list,html_param_items(user_model,field_type(),pipeline.name*"_"*process.name,field_name))
  end

  on(getfield(user_model,Symbol(string(pipeline.name)*"_"*process.name*"_execute"))) do _
    @info "execute is call"
    execute_pipeline(user_model,pipeline,node)
  end

  return q__card(class="q-pa-md", [p("Param for Process : "*string(process.name)),mydiv(list),

    StippleUI.btn("Execute ",@click(string(pipeline.name)*"_"*process.name*"_execute = !"*string(pipeline.name)*"_"*process.name*"_execute"))
  
  ])
end


function pipeline_render(user_model,pipeline)
q__card([
  "PIPELINE : "*pipeline.name,
  mydiv(class="q-pa-md",[
  html_param_node(user_model,pipeline,n)
  for n in pipeline.nodes
  ]),
  StippleUI.btn("Execute Pipeline ",@click(string(pipeline.name)*"_execute = !"*string(pipeline.name)*"_execute"))
])
end



function image_tabs(user_model,spliter_number)

  mydiv([
      q__tabs([

        q__tab([
          mydiv(class="row  items-center",[

              " {{list_image[image_str].img_id}} ",q__btn([],@click("image_viewer[$spliter_number].splice(index, 1)"),flat="", icon="close"),
              q__btn([],@click("image_viewer[$spliter_number].splice(index, 1);image_viewer[($spliter_number+1)%2].push(image_str);tabs_model[($spliter_number+1)%2]=image_str
              
              "),flat="", icon="vertical_split")
          ])


        ],@recur("(image_str,index) in image_viewer[$spliter_number]"),name! = "list_image[image_str].img_id", key! = "list_image[image_str].img_id", @click("selected_image=list_image[image_str].img_id"))

      ],@bind("tabs_model[$spliter_number]"),dense="",narrow__indicator=""),
      q__tab__panels(
        [
          q__tab__panel([

          StippleUI.imageview([],alt = "Format not suported",@click("selected_image=list_image[image_str].img_id");key! = "list_image[image_str].img_id",src! = "'/image?path='+list_image[image_str].image_path",  ),

          ],@recur("image_str in image_viewer[$spliter_number]"),name! = "list_image[image_str].img_id"),

          q__tab__panel(["Select a iamge in tab"],name! ="''")
        ],
        @bind("tabs_model[$spliter_number]"),animated=""
      )

  ])

end


function main_page(user_model)
    
    mydiv(class="",[
    
    q__splitter([
    Genie.Renderer.Html.template("",
      var"v-slot:before"="",
      [
        image_tabs(user_model,0)
      ]
    ),
    Genie.Renderer.Html.template("",
    var"v-slot:after"="",
    [
      image_tabs(user_model,1)
    ]
  )
    ],@bind("splitter")
    
    )
    
    ]
    )
end

function image_list_layout(user_model)

  # on(user_model.selected_visual_plugin) do _
  #   if(user_model.selected_image[]!="" && user_model.selected_visual_plugin[]!="")
    
  #     execute_plugin(user_model,Symbol(user_model.selected_visual_plugin[]))
  #   end
    
  # end


  q__card([
  mydiv(class="",
  [
    q__list([

      q__item(
      [
        q__item__section(["{{image_id}} : {{image.image_path}}"])

      ],
      @recur("(image,image_id) in list_image"),
      clickable="",
      v__ripple="",
      active! ="selected_image === image_id",
      active__class="active-link",
      @click("selected_image=image_id"),
      var"v-on:dblclick"="image_viewer[0].push(image_id)"
      )

    ],bordered="",padding=""),


    # q__list([

    #   q__item(
    #   [
    #     q__item__section([""*string(visul_plugin.first)])

    #   ],
    #   clickable="",
    #   v__ripple="",
    #   active! = "selected_visual_plugin == '"*string(visul_plugin.first)*"' ",
    #   active__class="active-link",
    #   @click("selected_visual_plugin = \""*string(visul_plugin.first) *"\" "),
    #   ) for visul_plugin in visual_plugin_list()

    # ],bordered="",padding=""),
  ]
  ),
  
  
  
  ])
  
end

function remote_file_opener(user_model)
  
end

function menupage(user_model)
  #style="height = calc(100vw-50px);"
    mydiv(class="column justify-between fit no-wrap",[
     #mydiv(html_param(user_model,:cropper,Param))
     pipeline_render(user_model,pipelines()["croper"])
    ,
     uploader()
     ,
     mydiv([
     image_list_layout(user_model)
     ])

     #map(p -> html_param(p[3]),plugin_list())
     
     ]
    )
end

function uploader()

  return StippleUI.uploader([],:multiple,:batch,:auto__upload,url="/upload",label="Image upload",  method = "POST", no__thumbnails = true,
   #var"v-on:uploaded"="""(i)=>{for(let file of i['files']){list_image[file.name] = {img_id:file.name,image_path:'/dev/shm/'+file.name}}}"""
  )
end

function page_loyout(content,drawer)
    StippleUI.layout(view="hHh lpR fFf",[
      q__header(class="bg-primary text-white" , reveal="",bordered="",
      [
        StippleUI.q__toolbar([
            StippleUI.btn("", dense="", flat="", round="",icon="menu",@click("leftDrawerOpen=!leftDrawerOpen")),
           
             "{{ debug}}"

        ]

        )

      ]),
      StippleUI.q__drawer(show__if__above="",side="left",bordered="",v__model="leftDrawerOpen",
        drawer
      ),
      StippleUI.q__page__container(
      content
      )


    ])

  end


  #
function ui(user_model)


  [

    page(user_model,class="container",
      prepend=[
        css()
      #Stipple.Elements.stylesheet("https://cdn.jsdelivr.net/npm/vue-draggable-resizable@2.3.0/dist/VueDraggableResizable.css")
      ]
      ,
     [
      page_loyout([
             main_page(user_model)

      ],
      [
        menupage(user_model)

      ])


  ] ),

  #Genie.Renderer.Html.script(src = "https://cdn.jsdelivr.net/npm/vue-grid-layout@2.4.0/dist/vue-grid-layout.umd.js"),

  


  #Genie.Assets.channels_support(), # auto-reload functionality relies on channels
  #GenieAutoReload.assets()
  ]
end

user_model = Stipple.init(Model)

route("/") do 
  html(ui(user_model), context = @__MODULE__)
end


route("/image") do 
  @info  Genie.Requests.getpayload(:path,"")
  Genie.Router.serve_file(Genie.Requests.getpayload(:path,""))
end
 
route("/upload", method = POST) do 
  #@info  Genie.Requests.getpayload(:imgs,"")

  @info "upload files "
  arr = []
   for (k,v) in Genie.Requests.filespayload()

     path = UPLOAD_PATH*k # WARNING NO DATAFILTERED
     open(path, "w") do io
      write(path, v.data)
    end
    user_model.list_image[][k] = ZzImage(k,path)
    push!(user_model)
   end
   Genie.Renderer.Json.json(arr)
end


# using Revise
# faire fonciotn start and stop 
Genie.config.websockets_server = true
#GenieAutoReload.autoreload(joinpath(pwd(),"src"),devonly = false)
up(async=isinteractive()) # or `up(open_browser = true)` to automatically open a browser window/tab when launching the app



end
