

"""
Define some js html method use is vue js
"""
Stipple.js_methods(::Model) = """ lazyload({ node, key, done, fail })
{
      // Function to fech sub list derectory when on clink on arrow of tree for remote file explorer
      let path = node.path
      fetch('/readdir?path='+path).then(res => res.json()).then(function (data) {
        
      done(data)
      })



},
delete_image(image_id)
{
      // Helper fucniton to delete image in list of load image
    Vue.delete(this.list_image, image_id)
    if(this.image_viewer[0].indexOf(image_id)!=-1)
      this.image_viewer[0].slice(this.image_viewer[0].indexOf(image_id))
    if(this.image_viewer[1].indexOf(image_id)!=-1)
      this.image_viewer[1].slice(this.image_viewer[1].indexOf(image_id))
},
removeEmpty(arrr) {
  return arrr.map(obj=> Object.fromEntries(Object.entries(obj).filter(([_, v]) => v != null)));
},
split_image(splitter_num,index,image_str)
{
  let another_image_id = "";
  if(index==0 && this.image_viewer[splitter_num].length>0)
    another_image_id = this.image_viewer[splitter_num][1]
  else
    another_image_id = this.image_viewer[splitter_num][0]

  this.image_viewer[splitter_num].splice(index, 1);
  
  if(this.image_viewer[(splitter_num+1)%2].indexOf(image_str)==-1)
  {
    this.image_viewer[(splitter_num+1)%2].push(image_str)
  
  };
    
  let tm = ["",""]
  tm[(splitter_num+1)%2] = image_str.toString()
  tm[(splitter_num)%2]   = another_image_id.toString()

  let self =this;
  setTimeout(()=>self.tabs_model = tm,10) 
}
"""

Stipple.js_computed(::Model) ="""

spliter_limit()
{
    let min = 0;
    let max = 100;

    if(this.image_viewer[0].length>0)
    {
      min=10;
    }
    if(this.image_viewer[1].length>0)
    {
        max=90;
    }

    return [min,max];
},




"""