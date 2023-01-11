using Stipple

# macro inputer(expr,expr)
#     expr isa Expr && expr.head === :struct || error("Invalid usage of inputer")
#     expr = expr::Expr
# end

Stipple.@kwdef  struct Roi
    x1::R{Int} = 0
    x2::R{Int}  = 0
    y1::R{Int}  = 0
    y2::R{Int}  = 0
end


Stipple.@kwdef struct Slider
    v::R{Int} = 0
    # function SliderInt{M, Max,Step}(v::Int=0)
    #     new{M, Max,Step}(v)
    # end
end


## TESS MODULE

struct Input
    image
end

Stipple.@kwdef mutable struct Param 
    roi::Roi
    theata::Slider
end

struct Output 
    image
end




function main(input,param)
    return input.image[param.roi.y1:param.roi.y2,param.roi.x1:param.roi.x2]
end

# function ask(param::SliderInt)
#     print("set param for slider as 5: ")
#     param.v = 5
# end

function ask(param::Roi)
    print("ask roi ")
    param.x1 = 5
    param.x2 = 150
    param.y1 = 5
    param.y2 = 150
end


function ask_param(param)
    for name in fieldnames(typeof(param))
     ask(getproperty(param,name)) 
    end

end



# using FileIO

# param = Param()
# ask_param(param)
# println(param)


# input = Input(load("/home/bgirard/Téléchargements/P1100111-2.jpg"))

# main(input,param)