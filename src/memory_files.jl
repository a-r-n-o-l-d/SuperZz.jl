

"""
Defnie la taille max des fichier en memoire
"""
const MAX_NBR_MEMORY_FILE = 1000

"""
String for test if fiel are inmory or real file on filesystem
"""
const START_PATH_FOR_MEMORY = "inmemory:"


mutable struct File
    path::String
    data::Any
    File(i,d) = new(i,d)
end

"""
virtual File are stored in a LRU cache sorted by path,
if the number of file are garther than MAX_NBR_MEMORY_FILE the older file are droped
"""
File_MEMORY = LRU{String,File}(maxsize=MAX_NBR_MEMORY_FILE)

physical_CACHE = LRU{String,Any}(maxsize=MAX_NBR_MEMORY_FILE)

"""
save file in virtual memor or in file sysmtem
"""
function save(file::File)
    if(is_memory_file(file))
        # here overwrite
        setindex!(File_MEMORY, file, file.path)
    else
        open(path, "w") do io
            write(file.path, file.data)
          end
    end    
end

"""
If file exit in virutal memeory return it else false
"""
function get_file(path)
    get(File_MEMORY,path) do 
        # TODO if file is not in memeory load it an return it
        return false
    end 
end

"""
loaf a file form virtual memory and decode it if needed
"""
function load_from_memory(path)
    if(is_memory_file(path))
        # TODO may be wrong format
        return PNGFiles.load(get_file(path).data)
      else
        get!(physical_CACHE,path) do 
            load(path)
        end
      end
end


"""
Serve A File throud HTTP
"""
function serve_file(f::File) :: HTTP.Response


    if( f == false)
        error("not found", Genie.Router.response_mime(), Val(404))
        return
    end
    paht = f.path
    fileheader = Genie.Router.file_headers(paht)
    return HTTP.Response(200, fileheader, body = f.data)

  end

"""
check thet a file is in memory 
"""
function is_memory_file(path)
    if(startswith(path,START_PATH_FOR_MEMORY))
        return true
    end
        return false
end

function is_memory_file(file::File)
    if(startswith(file.path,START_PATH_FOR_MEMORY))
        return true
    end
        return false
end