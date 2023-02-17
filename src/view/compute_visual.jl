


Stipple.@kwdef struct VisualDimentionSlider
    v::Vector{Int} = [1]
    step_v::Vector{Int} = [1]
    min_v::Vector{Int} =  [1]
    max_v::Vector{Int} = [1]
end


Stipple.@kwdef struct VisualParam
    slider::VisualDimentionSlider{Int} = VisualDimentionSlider()
end


function compute_visual_if_needed(user_model,zzinput)

    
end
