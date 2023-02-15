function plugin_render(user_model,name)
    return iframe(src = "/plugin/$(name)",style="height: 100%;border:none;")
  end


function plugin_list(user_model)
    mydiv( class="overflow-auto fit",
      [
        mydiv( 
          [
             plugin_render(user_model,p)
             ]
        ) for p in PLUGIN_LIST
      ]
    )
    
  end