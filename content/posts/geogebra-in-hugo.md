+++
title = "How to Embed the GeoGebra Calculator App in a Hugo Static Site"
description = "How to embed interactive geometry demos in Hugo static sites."
date =  2023-02-25
toc = false
draft = true
+++

One thing I figured out when writing "{{< newtabref href="/posts/raycasting" >}}Write a First Person Game in 2KB With Rust{{</ newtabref >}}" was how to embed the {{< newtabref href="https://geogebra.org" >}}GeoGebra{{</ newtabref >}} calculator into a {{< newtabref href="https://gohugo.io" >}}Hugo{{</ newtabref >}} site.
GeoGebra is a website that lets you design interactive diagrams for teaching geometry.
In my opinion, it's pretty impressive to explain a concept then have an interactive diagram right below the text for the reader to try themselves.

I don't think this has ever been done before in a hugo site, so I've decided to share how I did it in case someone else needs to do it in the future.

First, you need to include the `<script>` for the GeoGebra library in your site's `<head>`:

```html
{{ if .Page.Store.Get "hasGeogebra" }}
<script src="https://www.geogebra.org/apps/deployggb.js"></script>
{{ end }}
```

Then, create a hugo shortcode at `layouts/shortcodes/geogebra.html`:

```html
{{ .Page.Store.Set "hasGeogebra" true }}

<script>
  window.addEventListener("load", function() { 
    new GGBApplet({
      appName: "geometry",
      id: '{{ .Get "name" | default "geogebra" }}',
      showToolBar: false,
      showZoomButtons: false,
      showAlgebraInput: false,
      showLogging: false,
      enableRightClick: false,
      enableShiftDragZoom: false,
      preventFocus: true,
      showMenuBar: false,
      appletOnLoad: (api) => {
        api.setCoordSystem({{ .Get "coords" | safeJS }});  
      },
      filename: '{{ .Site.BaseURL }}{{ .Get "file" }}'
    }).inject('{{ .Get "name" | default "geogebra" }}');
  });
</script>

<figure>
  <div id='{{ .Get "name" | default "geogebra" }}'></div>
  <figcaption>{{ .Get "caption" | markdownify }}</figcaption>
</figure>
```
These are the options that I've set to make the diagrams feel "seamless" on my site, but if you want to enable the other parameters feel free to do so.
Here's a handy reference to the {{< newtabref href="https://wiki.geogebra.org/en/Reference:GeoGebra_App_Parameters" >}}`GGBApplet`'s constructor parameters{{</ newtabref >}}, there are a lot.

Now you can add GeoGebra diagrams right in your markdown by calling it like this:
```markdown
{{</* geogebra
    file="ggb/wallace-simson.ggb"
    name="wallace-simson"
    caption="The Wallace-Simson Line"
*/>}}
```

{{< geogebra file="ggb/wallace-simson.ggb" caption="The Wallace-Simson Line" >}}

*If you have more than one embed on a single page you need to set the `name` parameter or else it will break.*

Oh, and if you go around digging in the browser devtools looking for the GeoGebra calculator's CSS class, it's `GeoGebraFrame`:
```css
.GeoGebraFrame {
  border-width: 0px !important;
  user-select: none !important;
}
```