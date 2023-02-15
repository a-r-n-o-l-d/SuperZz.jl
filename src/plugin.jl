

# Plugin interface

function get_user_model()::Model
    global PLUGIN_ENV
    return PLUGIN_ENV.user_model
end


function zzview_select_by_user()::ZzView
    user_model = get_user_model()
    for (k,v) in user_model.list_image[]
        if k==user_model.selected_image[]
            return v
        end
      end
    throw(ArgumentError("No image selected"))
end

function load_data(view::ZzView)
    throw("not imlemented")
end

function load_data(view::ZzImage)
    return load_from_memory(view.image_path)
end

function load_data(view::ZzPlot)
    return view.data
end

"""
Add/or update data to list of selectable zzview and update on ui

"""
function add_data_list(img_id,img_name,image,is_visual=false)
    
    user_model = get_user_model()

    filename = START_PATH_FOR_MEMORY*img_id*"V.png"
    buf = IOBuffer()
    PNGFiles.save(buf, image)
    data = take!(buf)
    save(File(filename,data))

    @info "save $filename with $img_id"

    if haskey(user_model.list_image[],img_id)
      user_model.list_image[][img_id].image_version+=1

      if is_visual
        user_model.list_image[][img_id].img_visual_path=filename
      else
        user_model.list_image[][img_id].image_path=filename
      end

    else
      user_model.list_image[][img_id] = ZzImage(img_id=img_id,image_path=filename,image_version=1,img_name=img_name)
    end
    # updat model on web
    push!(user_model,:list_image)

end

function add_data_list(img_id,img_name,data::Vector{PlotData},is_visual=false)

    if haskey(user_model.list_image[],img_id)
        user_model.list_image[][img_id].data=data
    else
        user_model.list_image[][img_id] = ZzPlot(img_id=img_id,data=data,img_name=img_name)
    end
    # updat model on web
    push!(user_model,:list_image)
  end


function derive_name(plugin_name,view::ZzView)
    img_id   = plugin_name*""*view.img_id
    img_name = plugin_name*""*view.img_name
    
    return (img_id,img_name)
  end

function run_pipeline_with_error_check(f)
    try
        f()
    catch e
        StippleUI.notify(get_user_model(), "Error in pipeline : $e", :negative)

        if !(e isa ArgumentError)
          @error "Error in pipeline" exception=(e, catch_backtrace())
        end
        return nothing
    end
end


PLUGIN_LIST = []