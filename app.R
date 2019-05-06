# Carrega os pacotes necessários

library(shiny)
library(ggmap)
library(leaflet)
library(RMySQL)
library(shinydashboard)

# Registra a key api do google
register_google("AIzaSyB5UBTrdTRAlwWVxXiYoaFQTnXUaMGzh3s")




# Gera a UI
ui <- dashboardPage(
  dashboardHeader(title = "MAPA GERAL"),
  dashboardSidebar(
    sidebarMenu(
      menuItem("MAPA GERAL", tabName = "mapa", icon = icon("leaf"))
    )
  ),
  dashboardBody(
    tabItems(
      tabItem(tabName ="mapa",
              fluidRow(leafletOutput("map")))
    )
  )
)


# Gera o server
server <- shinyServer(function(input, output, session) {
  
  # Cria um data frame com as informações dos marcadores que foram criados:
  #dat <- reactiveValues(circs = data.frame(lng=numeric(), lat=numeric()))
  
  # Pega os dados de marcadores no banco
  con = dbConnect(RMySQL::MySQL(), 
                  user='mapa', 
                  password='123456', 
                  dbname='mapa', 
                  host='104.154.236.5')
  
  query <- 'select * from MAPAS'
  
  res <- dbSendQuery(con, query)
  df_marcadores <- dbFetch(res)
  
  dbDisconnect(con)
  
  # Plota o mapa inicial
  output$map <- renderLeaflet({
    leaflet() %>%
      setView(lng = -56.074194, lat =-15.568689 , zoom = 14) %>%
      addTiles(options = providerTileOptions(noWrap = TRUE)) %>% 
      addMarkers(data = df_marcadores, lng=~lng, lat=~lat)
  })
  
  # Gera os marcadores conforme o clique do mouse
  observeEvent(input$map_click, {
    click <- input$map_click
    clat <- click$lat
    clng <- click$lng
    address <- revgeocode(c(clng,clat))
    
    # Adiciona o marcador no gráfico
    leafletProxy('map') %>% # use the proxy to save computation
      addMarkers(lng=clng, lat=clat)
    
    con = dbConnect(RMySQL::MySQL(), 
                    user='mapa', 
                    password='123456', 
                    dbname='mapa', 
                    host='104.154.236.5')

    query <- paste0("insert into MAPAS (lat,lng) values (",
                    click$lat,
                   ",",
                   click$lng,")")
    print(query)
    dbSendQuery(con, query)
    dbDisconnect(con)
  })
  
})

shinyApp(ui=ui, server=server)