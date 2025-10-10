# ===============================================================
# model_shiny_confirm.R - Dự đoán điểm học sinh với nút xác nhận
# ===============================================================

library(shiny)
library(xgboost)
library(ggplot2)

# -------------------------------
# 1️⃣ Đọc dữ liệu và huấn luyện
# -------------------------------
if (!file.exists("student_performance_clean.csv")) {
  stop("Không tìm thấy file student_performance_clean.csv!")
}

data <- read.csv("student_performance_clean.csv")
cols_to_keep <- c('studytime', 'failures', 'internet', 'G1', 'G2', 'G3')
data <- data[, cols_to_keep]
data$internet <- as.numeric(as.factor(data$internet)) - 1

train_index <- sample(1:nrow(data), 0.7*nrow(data))
train_data <- data[train_index, ]
train_X <- as.matrix(train_data[, c('studytime','failures','internet','G1','G2')])
train_y <- train_data$G3

dtrain <- xgb.DMatrix(data = train_X, label = train_y)
params <- list(objective="reg:squarederror", eta=0.1, max_depth=5, subsample=0.8)
model <- xgb.train(params=params, data=dtrain, nrounds=100, watchlist=list(train=dtrain), verbose=0)

# -------------------------------
# 2️⃣ Giao diện Shiny
# -------------------------------
ui <- fluidPage(
  titlePanel("📊 Dự đoán điểm G3 học sinh"),
  
  sidebarLayout(
    sidebarPanel(
      numericInput("studytime", "Thời gian học (1-4):", value=1, min=1, max=4),
      numericInput("failures", "Số lần trượt (0-3):", value=0, min=0, max=3),
      selectInput("internet", "Có internet:", choices=c("Yes"=1, "No"=0)),
      numericInput("G1", "Điểm G1 (0-20):", value=10, min=0, max=20),
      numericInput("G2", "Điểm G2 (0-20):", value=10, min=0, max=20),
      actionButton("predict_btn", "✅ Dự đoán")
    ),
    
    mainPanel(
      h3("Kết quả dự đoán:"),
      verbatimTextOutput("prediction"),
      hr(),
      h3("Biểu đồ Actual vs Predicted"),
      plotOutput("pred_plot", height="500px")
    )
  )
)

# -------------------------------
# 3️⃣ Server logic
# -------------------------------
server <- function(input, output, session) {
  
  # Dự đoán khi nhấn nút
  predicted <- eventReactive(input$predict_btn, {
    new_data <- data.frame(
      studytime = input$studytime,
      failures  = input$failures,
      internet  = as.numeric(input$internet),
      G1        = input$G1,
      G2        = input$G2
    )
    predict(model, xgb.DMatrix(as.matrix(new_data)))
  })
  
  output$prediction <- renderText({
    req(predicted())
    paste0("Điểm G3 dự đoán: ", round(predicted(), 2))
  })
  
  # Biểu đồ Actual vs Predicted
  output$pred_plot <- renderPlot({
    pred_all <- predict(model, xgb.DMatrix(as.matrix(data[, c('studytime','failures','internet','G1','G2')])))
    plot_data <- data.frame(
      Actual = data$G3,
      Predicted = round(pred_all,2)
    )
    
    ggplot(plot_data, aes(x=Predicted, y=Actual)) +
      geom_point(color="#1f77b4", size=4, alpha=0.7) +
      geom_smooth(method="lm", color="#d62728", se=FALSE, size=1.2) +
      ggtitle("Biểu đồ: Dự đoán vs Thực tế (G3)", subtitle="Mô hình XGBoost") +
      xlab("Predicted G3") + ylab("Actual G3") +
      theme_light(base_size = 16)
  })
}

# -------------------------------
# 4️⃣ Chạy Shiny App
# -------------------------------
runApp(list(ui=ui, server=server))
