

"""
Define a remote file explorer html compoant with tree to explore file on serveur
"""
function remote_file_opener(user_model)

    on(user_model.files_selected) do _
      path =  user_model.files_selected[]
      if !isdir(path)
        img_id=  basename(path)
        if haskey(user_model.list_image[],img_id)
          user_model.list_image[][img_id].image_path=path
          user_model.list_image[][img_id].image_version+=1
        else
          user_model.list_image[][img_id] = ZzImage(img_id=img_id,image_path=path,image_version=1)
        end
  
      end
      push!(user_model,:list_image)
    end
  
  
    mydiv([
      q__tree([],nodes! = "files_tree",dense="",var":selected.sync"="files_selected",node__key="path",
      # var"@update:selected" = "
      # (['png', 'tiff', 'jpg'].includes(\$event.split('.').pop()))?list_image[\$event] = {img_id:\$event,image_path:\$event,image_version:0}:false
      # ",
      var"v-on:lazy-load"="""lazyload"""
      )
  
    ])
    
  end


#Route to get list of file on serveur 
# Warnign no security !!!
route("/readdir") do 
    @info "readir:" Genie.Requests.getpayload(:path,"/")
   
    path = Genie.Requests.getpayload(:path,"/")
    if path ==""
      path="/"
  
    end
    files = []
    for item in  readdir(path)
      if(startswith(item,"."))
        continue
      end
      if isdir(path*"/"*item)
        push!(files,Dict("label"=>item,"path"=>path*"/"*item,"lazy"=>true))
      else
        push!(files,Dict("label"=>item,"path"=>path*"/"*item))
      end
  
    end
    json(files)
  
  end