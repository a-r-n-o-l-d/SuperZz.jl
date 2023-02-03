function uploader()

    return StippleUI.uploader(class="uploadclass", [],:multiple,:batch,:auto__upload,url="/upload",label="Image upload",  method = "POST", no__thumbnails = true,
     #var"v-on:uploaded"="""(i)=>{for(let file of i['files']){list_image[file.name] = {img_id:file.name,image_path:'/dev/shm/'+file.name}}}"""
    )
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
      user_model.list_image[][k] = ZzImage(img_id=k,image_path=path,image_version=1,img_name=k)
      push!(user_model)
     end
     Genie.Renderer.Json.json(arr)
  end