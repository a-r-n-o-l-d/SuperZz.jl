



Stipple.@kwdef struct Roi
    name::String = ""
end

Base.@kwdef struct Slider
    v::Float32 = 0
    # function SliderInt{M, Max,Step}(v::Int=0)
    #     new{M, Max,Step}(v)
    # end
end




function flat_reactive_struct(type::DataType,prefix="")
    fields_sub_type = []

    fields = fieldnames(type)

    values = getfield.(Ref(type()), fields)

    for (field_name,field_type,v) in zip(fields,fieldtypes(type),values)
        if length(fieldnames(field_type)) > 0 

            push!(fields_sub_type,
            flat_reactive_struct(field_type,string(prefix)*string(field_name)*"_")...
            )

        else
            push!(fields_sub_type,
            :($(Symbol(prefix*string(field_name)))::R{$(field_type)} = $(v))
            )
        end
    end
    return fields_sub_type
end

function flat_var_reactive_struct(model,param::Any,prefix="")

    type = typeof(param)
    fields = fieldnames(type)

    values = getfield.(Ref(param), fields)

    for (field_name,field_type,v) in zip(fields,fieldtypes(type),values)
        if length(fieldnames(field_type)) > 0 
            flat_var_reactive_struct(model,v,string(prefix)*string(field_name)*"_")
        else
            getfield(model,Symbol(string(prefix*string(field_name))))[] = v 
        end
    end

end

    
function unflat_reactive_struct(type::DataType,flat::Any,prefix="")
    dict_arg = Dict()
    for (field_name,field_type) in zip(fieldnames(type),fieldtypes(type))
        if length(fieldnames(field_type)) > 0 

            dict_arg[field_name] = unflat_reactive_struct(field_type,flat,string(prefix)*string(field_name)*"_")
            
        else
            dict_arg[field_name] = getfield(flat,Symbol(string(prefix)*string(field_name)))[]
        end
    end
    return type(;dict_arg...)
end

