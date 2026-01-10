
library(rdeck)
library(arrow)
# install_arrow()
library(sf)
library(dplyr)
library(tigris)
library(rdeck) # pak::pak("rdeck")
options(tigris_use_cache = TRUE)


buildings <- open_dataset('s3://overturemaps-us-west-2/release/2024-05-16-beta.0/theme=buildings?region=us-west-2')

nrow(buildings)


sf_bbox <- counties(state = "CA", cb = TRUE, resolution = "20m") |> 
  filter(NAME == "San Francisco") |> 
  st_bbox() |> 
  as.vector()

sf_buildings <- buildings |>
  filter(bbox$xmin > sf_bbox[1],
         bbox$ymin > sf_bbox[2],
         bbox$xmax < sf_bbox[3],
         bbox$ymax < sf_bbox[4]) |>
  select(id, geometry, height) |> 
  collect() |>
  st_as_sf(crs = 4326) |> 
  mutate(height = ifelse(is.na(height), 8, height))


rdeck(map_style = mapbox_light(), 
      initial_view_state = view_state(
        center = c(-122.4657, 37.7548),
        zoom = 11.3,
        bearing = -60,
        pitch = 76
      )) |> 
  add_polygon_layer(
    data = sf_buildings, 
    name = "San Francisco",
    get_polygon = geometry, 
    get_elevation = height, 
    get_fill_color = scale_color_linear(
      col = height,
      palette = viridisLite::inferno(100, direction = -1)
    ),
    extruded = TRUE, 
    opacity = 0.5)