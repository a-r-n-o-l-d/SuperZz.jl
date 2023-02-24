function plugin_render(user_model,name)
    return iframe(src = "/plugin/$(name)",style="border:none;",class="gh-fit")
  end


function plugin_list(user_model)
    mydiv( class="column no-wrap",
      [

             plugin_render(user_model,p)
             #mydiv(["Empty div"],style="height:500px;")
             
         for p in Iterators.reverse(PLUGIN_LIST)
      ]
      
    )
    
  end