include("html_param.jl")
include("cropper_plugin.jl")


function plugin_list()
  return Dict(:cropper=>CropperPlugin,:raw_visual_plugin=>DefaultVisualPlugin,:gray_visual=>GrayVisualPlugin,:dimentional_visual=>DimentionalVisualPlugin)
end


function visual_plugin_list()
    filter(i->i.second.is_visual,plugin_list())
end



function plugin_dict_pram()

  return Dict(k=>v.Param for (k,v) in  plugin_list())
end


function PluginStructGenerator()  
    
  fields = [ ]
  for (key, value) in plugin_dict_pram() 

    fields_sub_type = flat_reactive_struct(value,string(key)*"_")

    push!(fields_sub_type,
    :($(Symbol(string(key)*"_"*"execute"))::R{Bool}=false)
    )

    push!(fields,fields_sub_type...)
    
  end

  eval(quote
      Stipple.@kwdef struct Plugins
        $(fields...) 
          end
   end)
end

function param_generator(user_model,symbol_plugin,paramtype)

  pram = unflat_reactive_struct(paramtype,user_model,string(symbol_plugin)*"_") 
  @info "param genrate"
  @info pram
  return pram
end


function select_image(user_model)
    for (k,v) in user_model.list_image[]
        if k==user_model.selected_image[]
            return v
        end
      end
end


function execute_plugin(user_model,symbol_plugin)
    @info "execute "*string(symbol_plugin)
  

    p = plugin_list()[symbol_plugin]
  
    param = param_generator(user_model,symbol_plugin,p.Param)
  
  
    @info "Selected image :", user_model.selected_image[]

    zzinput = select_image(user_model)
  
    @info "zzinput ok "
    input = p.Input(load(zzinput.image_path))
    @info "input in generate "
  
    @info param
  
    try
      output = p.f(input,param)
      @info "output in comuted"
      add_image_to_model(user_model,zzinput.img_id,string(symbol_plugin)*"_of_"*zzinput.img_id,output.image,p.is_visual)

    catch e
      @error "plugin went wrong" exception=(e, catch_backtrace())
    end

  end


function add_image_to_model(user_model,img_id,name,image,is_visual)

    filename = "/dev/shm/"*name*".png"
    save(filename,image)

  
    if is_visual
        idx = findall(i->i.img_id==name, user_model.image_viewer[][1])
        if !isempty(idx)
          user_model.image_viewer[][1][idx[1]],ImageViewer(image_path=filename,img_id=name,img_id_zz_image=img_id)
        else
          push!(user_model.image_viewer[][1],ImageViewer(image_path=filename,img_id=name,img_id_zz_image=img_id))
        end

    else
      user_model.list_image[][name] = ZzImage(name,filename)
    end
    # updat model on web

    user_model.tabs_model[][1] = name 
    push!(user_model)
  end 