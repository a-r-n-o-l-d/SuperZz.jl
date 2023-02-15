"""
Vue composant and route to upload file

"""

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
  
      path = START_PATH_FOR_MEMORY*k # WARNING NO DATAFILTERED
      save(File(path,v.data))
      
      user_model.list_image[][k] = ZzImage(img_id=k,image_path=path,image_version=1,img_name=k)
      push!(user_model.list_image)
     end
     Genie.Renderer.Json.json(arr)
end