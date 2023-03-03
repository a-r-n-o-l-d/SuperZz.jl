Vue.component('l-map', window.Vue2Leaflet.LMap);
Vue.component('l-image-overlay', window.Vue2Leaflet.LImageOverlay);

var geoLayer = null;
Vue.component('l-viewer', {
    component : ["l-map","l-image-overlay"],
    template : `<div style="width : 100%;" ref="imagecontainer" class="viewercontainer">

    <div v-if="is_loading" class="loading" 
    style = "
      background: transparent url('https://miro.medium.com/max/882/1*9EBHIOzhE1XfMYoKz1JcsQ.gif') center no-repeat;
      height: 10vw;
      width: 100%;
    "
    ></div>

    <l-map v-show="!is_loading"   :crs="crs" :style="'height: '+stageheight+'px; width: 100%;max-height:100vh;'" 
    ref="map"
    :max-bounds="bound"
    :min-zoom="-2"
    >
    <l-image-overlay
    :url="src"
    :bounds="bound"

      />


    </l-map>
    Coucou 
    {{ image.src}}
    {{ rois}}
    </div>
    `,

    data() {
        return { 
            crs: L.CRS.Simple,
            width : 1000,
            height : 1000,
            image_height : 1000,
            image_width : 1000,
            image: new window.Image(),
            is_loading : true
        }
    },
    name: "l-viewer",
    model: {
      prop: "rois",
      event : "change"

    },
    props : ["src","rois"],
    computed: {

        bound()
        {
          return [[0,0],[this.image_height,this.image_width ]]
        },
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



        configImg: function() {
          console.log("configImg,",this.image)
            return {

              image: this.image,
            }
        },

    },
    methods:
    {



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

        
        this.$refs.map.mapObject.pm.addControls({  
          position: 'topleft',  
          drawCircle: false,  
        });  



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
            if(self.rois && self.rois.type == "FeatureCollection" ){
              console.log(self.rois)
                if(geoLayer)
                geoLayer.clearlayer();

                geoLayer = L.geoJSON(self.rois)
                geoLayer.addTo(this.$refs.map.mapObject);
            }
            }
        this.image.src=this.src;

        this.$refs.map.mapObject.on('pm:drawend', (e) => {
          console.log(e);
          console.log("drawend");

          var fg = L.featureGroup();    
          this.$refs.map.mapObject.eachLayer(
            layer => {
              if (
                (layer instanceof L.Polyline || //Don't worry about Polygon and Rectangle they are included in Polyline
                layer instanceof L.Marker ||
                layer instanceof L.Circle ||
                layer instanceof L.CircleMarker) && !!layer.pm && !layer._pmTempLayer)
                {
                fg.addLayer(layer);
              }
          })
          console.log(fg.toGeoJSON());

          self.$emit("change",fg.toGeoJSON());
        });


      },

      

}
)