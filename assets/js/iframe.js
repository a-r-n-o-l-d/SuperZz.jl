function fit() {
    var iframes = document.querySelectorAll("iframe.gh-fit")

    for(var id = 0; id < iframes.length; id++) {
        var win = iframes[id].contentWindow
        var doc = win.document
        var html = doc.documentElement
        var body = doc.body
        var ifrm = iframes[id] // or win.frameElement

        if(body) {
            body.style.overflowX = "scroll" // scrollbar-jitter fix
            body.style.overflowY = "hidden"
        }
        if(html) {
            html.style.overflowX = "scroll" // scrollbar-jitter fix
            html.style.overflowY = "hidden"
            var style = win.getComputedStyle(html)
            //ifrm.width = parseInt(style.getPropertyValue("width")) // round value
            ifrm.height = parseInt(style.getPropertyValue("height"))
        }
    }

    requestAnimationFrame(fit)
}

addEventListener("load", requestAnimationFrame.bind(this, fit))