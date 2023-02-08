
Vue.component('k-viewer', {

    template : `<div style="width : 100%;
    height : 100%;" ref="imagecontainer" class="viewercontainer">

    <div v-if="is_loading" class="loading" 
    style = "
      background: transparent url('https://miro.medium.com/max/882/1*9EBHIOzhE1XfMYoKz1JcsQ.gif') center no-repeat;
      height: 10vw;
      width: 100%;
    "
    ></div>

    <v-stage v-show="!is_loading" ref="stage" :config="configKonva" @wheel="handleScroll"
    @mouseenter="handleGlobalMouseEnter" 
    @mouseleave="handleGlobalMouseLeave"
    @mouseDown="handleMouseDown"
    @mousemove="handleMouseMove"
    @mouseUp="handleMouseUp"
    >
        <v-layer ref="layer">
        <v-group ref ="group">
          <v-image ref="konvasImg" :config="configImg">
          
          </v-image>
          <template v-for="(shape, name) in rois">
          <v-rect v-if="shape.type === 'rect'" :config="shape" :key="name"
          @dragend="handleDragEnd($event, shape,name)"
          
                    
                    />
          </template>
          </v-group>
        </v-layer>

    </v-stage>
    Coucou 
    {{ image.src}}
    {{ tool_selected }}
    </div>
    `,

    data() {
        return { 
            width : 1,
            height : 1,
            scale_zoom : 1.0,
            image_height : 1,
            image_width : 1,
            image: new window.Image(),
            is_editting :false,
            is_loading : true
        }
    },
    name: "k-viewer",
    model: {
      prop: "rois",
      event : "change"

    },
    props : ["src","tool_selected","rois"],
    computed: {

        stagewidth : function()
        {
            return parseInt(this.width);
        },
        stageheight : function()
        {
          return  parseInt(this.width*this.ratio);  
        },
        ratio()
        {

            return  this.image_height / this.image_width;
        },
        scale()
        {

            return this.stagewidth / this.image_width * this.scale_zoom
        },
        configKonva: function() {
            return {
            width: this.stagewidth,
            height: this.stageheight,
            scaleX: this.scale,
            scaleY: this.scale,
            draggable: true
            }
           },

        configImg: function() {
          console.log("configImg,",this.image)
            return {

              image: this.image,
            }
        },
        hastool()
        {
          return this.tool_selected["tool"] != undefined && this.tool_selected["tool"]!="" 
        },
        toolname()
        {
          return this.tool_selected["tool"]
        }
    },
    methods:
    {
      handleGlobalMouseEnter () {
        if (this.hastool) this.$refs.stage.getStage().container().style.cursor = 'crosshair';
      },
      handleGlobalMouseLeave () {
        if (this.hastool) this.$refs.stage.getStage().container().style.cursor = 'default';
      },

      rawPosToImagePos(pos)
      {
        var transform = this.$refs.group.getNode().getAbsoluteTransform().copy();
        // to detect relative position we need to invert transform
        transform.invert();
        // now we find relative point
        pos =  transform.point(pos);
        return pos;
      },
      getPosInImage()
      {
        let pos = this.$refs.stage.getNode().getPointerPosition();
        return this.rawPosToImagePos(pos);
      }
,
      handleMouseDown(event) {


        if(this.hastool && this.toolname=="roi")
        {
          console.log("handleMouseDown",event)
          event.evt.preventDefault();
          event.evt.stopPropagation();
          event.evt.stopImmediatePropagation();
            this.is_editting="roi_crop";
          let pos = this.getPosInImage();

            Vue.set( this.rois, 'roi_crop',
              {
                type:  "rect",
                x: pos.x,
                y: pos.y,
                width: 0, 
                height: 0,
                opacity: 0.5,
                draggable: true,
                fill: '#b0c4de',
                stroke: 'black',
                strokeWidth: 3,
              })
            
        }
      },
      handleMouseMove(event)
      {

            if(this.is_editting!=undefined && this.is_editting!=false)
            {

              event.evt.preventDefault();
              event.evt.stopPropagation();
              event.evt.stopImmediatePropagation();
              if(this.hastool && this.toolname=="roi")
              {
                let pos = this.getPosInImage();

                // handle  rectangle part

                let curRec = this.rois[this.is_editting];
                curRec.width = pos.x - curRec.x;
                curRec.height = pos.y - curRec.y;
              }
            }
      },
      handleMouseUp(e)
      {
        if(this.is_editting)
        {
          this.tool_selected["setter"](this.is_editting)
          this.is_editting=false;

          this.tool_selected["tool"] = ""
        }


      },

      handleDragEnd(e,shape,name)
      {
        console.log("drag end",name,shape,e)
        let np = this.rawPosToImagePos(e.target.getAbsolutePosition());
        this.rois[name].x = np.x;
        this.rois[name].y = np.y;
      },
        handleScroll (e) {
            if (e.evt) {
              const event = e.evt;
              event.preventDefault();
              // Normalize wheel to +1 or -1.
              const wheel = event.deltaY < 0 ? 1.1 : 1/1.10;



                let stage = this.$refs.stage.getStage()

                var pointer = stage.getPointerPosition();

              var mousePointTo = {
                x: (pointer.x - stage.x()) / this.scale,
                y: (pointer.y - stage.y()) /this.scale,
              };

              // calculate scale
              this.scale_zoom *=  wheel;


              var newPos = {
                x: pointer.x - mousePointTo.x * this.scale,
                y: pointer.y - mousePointTo.y * this.scale,
              };
              stage.position(newPos);

            }
          },
    },
    watch:
    {
        src(nv,ov)
        {
            console.log("updata")
            console.log(nv)
            //this.image.src=nv;
            this.image.src=this.src;
        }

    },

    mounted() {
        let self = this;

        const container = this.$refs.imagecontainer;
        self.width = container.offsetWidth;
        self.height = container.offsetHeight;
        console.log(container)
        const observer = new ResizeObserver(() => {
            console.log("resize "+container.offsetWidth)
            if(container.offsetWidth>10 &&container.offsetHeight>10 )
            {
              self.width = container.offsetWidth;
              self.height = container.offsetHeight;
            }

        });
        observer.observe(container);


        this.image.onload = () =>{

            console.log("laoded ")
            console.log(this.image)
            self.is_loading=false

            self.image_height=this.image.height;
            self.image_width=this.image.width;

            self.width = container.offsetWidth;
            self.height = container.offsetHeight;

            // self.width = this.image.width;
            // self.height = this.image.height;
            if( this.$refs.stage)
            {
             this.$refs.stage.getStage().size(self.configKonva)
             this.$refs.konvasImg.getStage().draw()
            }
            }
        this.image.src=this.src;

      },

}
)