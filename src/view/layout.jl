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

register_normal_element("q__page",context= @__MODULE__ )

function main_page(user_model)
    
     # q__scroll__area(class ="fit", [
    q__splitter(before__class="no-scroll",after__class="no-scroll",style="height: calc(100vh - 52px);",[
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
    ],@bind("splitter"),var":limits"="spliter_limit"
    
    )
   # ])

end

include("plugin_view.jl")



function rightmenupage(user_model)
    #style="height = calc(100vw-50px);"
    mydiv(style ="overflow-y:auto;", class ="fit", [
        plugin_list(user_model)
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


function page_loyout(user_model)
    StippleUI.layout(view="hHh LpR fFf",[
      q__header(class="bg-primary text-white" , reveal="",bordered="",
      [
        StippleUI.q__toolbar([
            StippleUI.btn("", dense="", flat="", round="",icon="menu",@click("leftDrawerOpen=!leftDrawerOpen")),
           
             "{{ debug}}"

        ]

        )

      ]),
      StippleUI.q__drawer(show__if__above="",side="left",bordered="",v__model="leftDrawerOpen",
      [menupage(user_model)]
      ),
      StippleUI.q__drawer(show__if__above="",side="right",bordered="",v__model="rightDrawerOpen",
      rightmenupage(user_model) 
      ),
      StippleUI.q__page__container(class=" absolute-full",
        [ main_page(user_model)]
      )


    ])

  end


"""

Define main ui layout

"""
function ui(user_model)


    [
  
      page(user_model,class="container",
        prepend=[
          css()
        #Stipple.Elements.stylesheet("https://cdn.jsdelivr.net/npm/vue-draggable-resizable@2.3.0/dist/VueDraggableResizable.css")
        ]
        ,
       [
        page_loyout(user_model)
  
  
    ] ),
  
    #Genie.Renderer.Html.script(src = "https://cdn.jsdelivr.net/npm/vue-grid-layout@2.4.0/dist/vue-grid-layout.umd.js"),
  

  
  
    #Genie.Assets.channels_support(), # auto-reload functionality relies on channels
    #GenieAutoReload.assets()
    ]
  end