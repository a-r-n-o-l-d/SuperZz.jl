module SuperZz

using Stipple
using GenieFramework
using FileIO
using Images
#import UUIDs
import Genie.Renderer.Html: HTMLString, normal_element, register_normal_element
using LRUCache
#using Plots, 
using StatsBase


@genietools

@info "SuperZZ Loaded"
Genie.Assets.add_fileroute(StippleUI.assets_config, "konva-viewer.js", basedir = pwd())

const mydiv = Genie.Renderer.Html.div
const UPLOAD_PATH = "/dev/shm/"

include("custom_log.jl")
include("zzimage.jl")
include("model.jl")

include("pipeline.jl")
include("html_param.jl")
include("visual_pipeline.jl")


register_normal_element("q__header",context= @__MODULE__ )

#register_normal_element("template",context= @__MODULE__ )












css() = style("""

.active-link
{
  color: white
  background: #F2C037
}
.uploadclass
{
  width : unset !important;
}

""")
  


# Plugin de test : 
# Sepapez les cannaux 
# Filtre gaussien

# Visialiton : 
# - slice
# - ZOOM 
# - LUT 


# loaded image





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

  return dict
end

function demo_image_viewer()

  [["SampleZZ"],[]]
end


PipelineStructGenerator()


@vars Model begin
  
    leftDrawerOpen::R{Bool} = true
    rightDrawerOpen::R{Bool} = true

    image_viewer::R{Vector{Vector{String}}} = demo_image_viewer()

    list_image::R{Dict{String,ZzView}} = demo_image()

    splitter::R{Int} = 100
    tabs_model::R{Vector{String}} = ["SampleZZ",""]


    tool_selected::R{Dict{String,Any}} = Dict{String,Any}("tool"=>"")


    selected_image::R{String} = ""
    previous_selected_image::String = ""

    debug::R{String} = ""


    filter::R{String} = ""

    files_tree::R{Vector{Dict{String,Any}}} = [Dict("label"=>"/","path"=>"/","lazy"=>true)]
    files_selected::R{String} = ""

    param_image_cache::Dict{String,Any} = Dict{String,Any}() # cache is not reactive

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
       push!(list,html_param_items(user_model,field_type(),pipeline.name*"_"*process.name,field_name,pipeline,node))
  end

  on(getfield(user_model,Symbol(string(pipeline.name)*"_"*process.name*"_execute"))) do _
    @info "execute is call for process $(process.name)"
    execute_pipeline(user_model,pipeline,node)
  end

  return q__card(class="q-pa-md", [p("Param for Process  : "*string(process.name)),mydiv(list),

    (!pipeline.is_visual) ? StippleUI.btn("Execute ",@click(string(pipeline.name)*"_"*process.name*"_execute = !"*string(pipeline.name)*"_"*process.name*"_execute")) : "" 
  
  ])
end


function pipeline_render(user_model,pipeline)


  on(getfield(user_model,Symbol(string(pipeline.name)*"_execute"))) do _
    @info "execute is call for pipeline $(pipeline.name) "
    execute_pipeline(user_model,pipeline,nothing)
  end

if pipeline.is_visual || length(pipeline.nodes) == 1
  return      mydiv(class="q-pa-md",[
    html_param_node(user_model,pipeline,n)
    for n in pipeline.nodes
    ])
else

  q__card([
    "PIPELINE : "*pipeline.name,
    mydiv(class="q-pa-md",[
    html_param_node(user_model,pipeline,n)
    for n in pipeline.nodes
    ]),

    ((!pipeline.is_visual) ? StippleUI.btn("Execute Pipeline ",@click(string(pipeline.name)*"_execute = !"*string(pipeline.name)*"_execute")) : "")
  ])
  end
end




register_normal_element("k__viewer",context= @__MODULE__ )



function konvas_render(user_model)
  k__viewer(
    tool_selected! = "tool_selected",
    src! = "'/image?path='+((list_image[image_str].img_visual_path)?list_image[image_str].img_visual_path:list_image[image_str].image_path)+'&v='+list_image[image_str].image_version",
    var"v-model"="list_image[image_str].rois",
  )
end


function view_render(user_model)

  template([
  # StippleUI.imageview([],alt = "Format not suported",@iif("list_image[image_str].type==\"ZzImage\"");
  # src! = "'/image?path='+((list_image[image_str].img_visual_path)?list_image[image_str].img_visual_path:list_image[image_str].image_path)+'&v='+list_image[image_str].image_version",  
  # ),
  template([konvas_render(user_model)],@iif("list_image[image_str].type==\"ZzImage\""))
  ,
  #
  StipplePlotly.plot("removeEmpty(list_image[image_str].data)",layout =  PlotLayout(plot_bgcolor = "#333", title = PlotLayoutTitle(text = "Random numbers", font = Font(24))),config =  PlotConfig(),

  @iif("list_image[image_str].type==\"ZzPlot\"") 
  )
  ]
  )
end


function image_tabs(user_model,spliter_number)

  mydiv([
      q__tabs([

        q__tab([
          mydiv(class="row  items-center",[

              " {{list_image[image_str].img_name}} ",
              
              q__btn([],@click("image_viewer[$spliter_number].splice(index, 1)"),flat="", icon="close"),

              q__btn([],@click(
                
          "split_image($spliter_number,index,image_str)"),flat="", icon="vertical_split")
          ])


        ],@recur("(image_str,index) in image_viewer[$spliter_number]"),name! = "list_image[image_str].img_id", key! = "list_image[image_str].img_id", @click(""))

      ],@bind("tabs_model[$spliter_number]"),dense="",narrow__indicator=""),
      q__tab__panels(
        [
          q__tab__panel([

          view_render(user_model)

          ],@click("selected_image=list_image[image_str].img_id"),key! = "list_image[image_str].img_id",@recur("image_str in image_viewer[$spliter_number]"),name! = "list_image[image_str].img_id"),

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
  on(user_model.selected_image) do _


      try
        for (key, pipe) in all_pipeline()
          for node in pipe.nodes 
              process= node.process

              # save all param for previous_selected_image
              param = param_generator(user_model,pipe.name,process.name,process.Param)
              if(user_model.previous_selected_image != "")
              user_model.param_image_cache[user_model.previous_selected_image*"_"*pipe.name*"_"*process.name] = param
              end
              # restore if exist
              if haskey(user_model.param_image_cache,user_model.selected_image[]*"_"*pipe.name*"_"*process.name)
                
                param_seter(user_model,
                user_model.param_image_cache[user_model.selected_image[]*"_"*pipe.name*"_"*process.name],
                pipe.name,process.name
                )
              end
          end
        end     
    
    catch e 
        @error "Error in selected_image" exception=(e, catch_backtrace())
      return nothing
      end



    user_model.previous_selected_image = user_model.selected_image[]
  end



  mydiv(class="q-pa-sm",
  [
    q__list([

      q__item(
      [
        q__item__section([
          q__input([],@bind("image.img_name"),dense=""),
        
        "{{image.image_path}}"
        
        
        ],@click("selected_image=image_id"),class="cursor-pointer ",clickable="",v__ripple="")

        q__item__section([
          q__btn([],round="",icon="preview",
          @click(
            "Visual_execute=!Visual_execute;(image_viewer[0].indexOf(image_id)==-1)?(image_viewer[0].push(image_id),tabs_model[0]=image_id):false"
            )
          ),
          q__btn([],round="",icon="close",@click("delete_image(image_id)"))

          
          ],avatar="")
      ]
      ,
      key! = "image_id"
      ,
      @recur("(image,image_id) in list_image"),
      active! ="selected_image === image_id",
      active__class="active-link",
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
  

  ])
  
end




include("remote_file_explorer.jl")


function pipeline_list(user_model)
  mydiv(class="fit overflow-auto",
  [
    q__input([],filled = "",label = "Filter" ,@bind("filter")),
    mydiv(
      [
        mydiv([ pipeline_render(user_model,p)],
        
        var"v-show"="'$k'.toLowerCase().indexOf(filter.toLowerCase())>-1"
        ) for (k,p) in pipelines()
      ]
    )


  ]

  )
end

function rightmenupage(user_model)
  #style="height = calc(100vw-50px);"
    mydiv(class="column  fit no-wrap justify-between",[
      pipeline_list(user_model),
     q__card([
      " Visual param",
     pipeline_render(user_model,VisualPipeLine)
     ])
     ]
    )
end

function menupage(user_model)
  #style="height = calc(100vw-50px);"
    mydiv(class="column  fit no-wrap",[
     #mydiv(html_param(user_model,:cropper,Param))

     mydiv([
     image_list_layout(user_model)
     ]),
     mydiv(
      class="q-pa-sm ",
     
     [uploader()]
     )
     ,remote_file_opener(user_model)



     #map(p -> html_param(p[3]),plugin_list())
     
     ]
    )
end
include("file_upload.jl")


function page_loyout(content,drawer,drawerright)
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
      StippleUI.q__drawer(show__if__above="",side="right",bordered="",v__model="rightDrawerOpen",
      drawerright 
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

      ],
      [
        rightmenupage(user_model)
      ]
      
      )


  ] ),

  #Genie.Renderer.Html.script(src = "https://cdn.jsdelivr.net/npm/vue-grid-layout@2.4.0/dist/vue-grid-layout.umd.js"),

  Genie.Renderer.Html.script(src = "https://cdnjs.cloudflare.com/ajax/libs/konva/8.4.2/konva.js"),
  Genie.Renderer.Html.script(src = "https://unpkg.com/vue-konva@2.1.7/umd/vue-konva.js"),

  Genie.Renderer.Html.script(src = "/stippleui.jl/master/assets/js/konva-viewer.js"),


  #Genie.Assets.channels_support(), # auto-reload functionality relies on channels
  #GenieAutoReload.assets()
  ]
end

Stipple.js_methods(::Model) = """
lazyload({ node, key, done, fail })
{

      let path = node.path
      fetch('/readdir?path='+path).then(res => res.json()).then(function (data) {
        
      done(data)
      })



},
delete_image(image_id)
{
    Vue.delete(this.list_image, image_id)
    if(this.image_viewer[0].indexOf(image_id)!=-1)
      this.image_viewer[0].slice(this.image_viewer[0].indexOf(image_id))
    if(this.image_viewer[1].indexOf(image_id)!=-1)
      this.image_viewer[1].slice(this.image_viewer[1].indexOf(image_id))
},
removeEmpty(arrr) {
  return arrr.map(obj=> Object.fromEntries(Object.entries(obj).filter(([_, v]) => v != null)));
},
split_image(splitter_num,index,image_str)
{
  let another_image_id = "";
  if(index==0 && this.image_viewer[splitter_num].length>0)
    another_image_id = this.image_viewer[splitter_num][1]
  else
    another_image_id = this.image_viewer[splitter_num][0]

  this.image_viewer[splitter_num].splice(index, 1);
  
  if(this.image_viewer[(splitter_num+1)%2].indexOf(image_str)==-1)
  {
    this.image_viewer[(splitter_num+1)%2].push(image_str)
  
  };
    
  let tm = ["",""]
  tm[(splitter_num+1)%2] = image_str.toString()
  tm[(splitter_num)%2]   = another_image_id.toString()

  let self =this;
  setTimeout(()=>self.tabs_model = tm,10) 
}

"""


user_model = Stipple.init(Model)

route("/") do 
  html(ui(user_model), context = @__MODULE__)
end


route("/image") do 
  @info  Genie.Requests.getpayload(:path,"")
  Genie.Router.serve_file(Genie.Requests.getpayload(:path,""))
end


 



# using Revise
# faire fonciotn start and stop 
Genie.config.websockets_server = true
#GenieAutoReload.autoreload(joinpath(pwd(),"src"),devonly = false)

# with_logger(zz_logger) do 

  up(async=isinteractive()) # or `up(open_browser = true)` to automatically open a browser window/tab when launching the app

#end

end
