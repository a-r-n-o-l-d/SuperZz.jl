


const MAX_NBR_MEMORY_FILE = 1000
const START_PATH_FOR_MEMORY = "inmemory:"

mutable struct File
    path::String
    data::Any
    File(i,d) = new(i,d)
end

File_MEMORY = LRU{String,File}(maxsize=MAX_NBR_MEMORY_FILE)




function save(file::File)
    if(startswith(file.path,START_PATH_FOR_MEMORY))
        # here overwrite
        setindex!(File_MEMORY, file, file.path)
    else
        open(path, "w") do io
            write(file.path, file.data)
          end
    end    
end

function get_file(path)
    get(File_MEMORY,path) do 
        return false
    end 
end

function load_from_memory(path)
    if(is_memory_file(path))
        # TODO may be wrong format
        return PNGFiles.load(get_file(path).data)
      else
        load(path)
      end
end


function serve_file(f::File) :: HTTP.Response


    if( f == false)
        error("not found", Genie.Router.response_mime(), Val(404))
        return
    end
    paht = f.path
    fileheader = Genie.Router.file_headers(paht)
    return HTTP.Response(200, fileheader, body = f.data)

  end

function is_memory_file(path)
    if(startswith(path,START_PATH_FOR_MEMORY))
        return true
    end
        return false
end