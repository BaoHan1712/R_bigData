# ===============================================================
# model_shiny_confirm_eval2.R - Dự đoán điểm học sinh với đánh giá train/test
# ===============================================================

library(shiny)
library(xgboost)
library(ggplot2)

# -------------------------------
# 1️⃣ Đọc dữ liệu và chuẩn bị
# -------------------------------
if (!file.exists("student_performance_clean.csv")) {
  stop("Không tìm thấy file student_performance_clean.csv!")
}

data <- read.csv("student_performance_clean.csv")
cols_to_keep <- c('studytime', 'failures', 'internet', 'G1', 'G2', 'G3')
data <- data[, cols_to_keep]
data$internet <- as.numeric(as.factor(data$internet)) - 1

set.seed(123)
train_index <- sample(1:nrow(data), 0.75*nrow(data))
train_data <- data[train_index, ]
test_data  <- data[-train_index, ]

train_X <- as.matrix(train_data[, c('studytime','failures','internet','G1','G2')])
train_y <- train_data$G3

test_X <- as.matrix(test_data[, c('studytime','failures','internet','G1','G2')])
test_y <- test_data$G3

# -------------------------------
# 2️⃣ Huấn luyện mô hình XGBoost
# -------------------------------
dtrain <- xgb.DMatrix(data = train_X, label = train_y)
dtest  <- xgb.DMatrix(data = test_X,  label = test_y)

params <- list(objective="reg:squarederror", eta=0.1, max_depth=5, subsample=0.8)
model <- xgb.train(params=params, data=dtrain, nrounds=100, watchlist=list(train=dtrain), verbose=0)

# -------------------------------
# 3️⃣ Hàm tính RMSE và R²
# -------------------------------
rmse_fun <- function(y_true, y_pred) sqrt(mean((y_true - y_pred)^2))
r2_fun   <- function(y_true, y_pred) 1 - sum((y_true - y_pred)^2)/sum((y_true - mean(y_true))^2)

pred_train <- predict(model, dtrain)
pred_test  <- predict(model, dtest)

rmse_train <- rmse_fun(train_y, pred_train)
r2_train   <- r2_fun(train_y, pred_train)

rmse_test  <- rmse_fun(test_y, pred_test)
r2_test    <- r2_fun(test_y, pred_test)

# -------------------------------
# 4️⃣ Giao diện Shiny
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
      actionButton("predict_btn", "✅ Dự đoán"),
      hr(),
      h4("Đánh giá mô hình:"),
      verbatimTextOutput("model_metrics")
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
# 5️⃣ Server logic
# -------------------------------
server <- function(input, output, session) {
  
  # Hiển thị RMSE và R²
  output$model_metrics <- renderText({
    paste0(
      "Train: RMSE=", round(rmse_train,2), ", R²=", round(r2_train,3), "\n",
      "Test : RMSE=", round(rmse_test,2),  ", R²=", round(r2_test,3)
    )
  })
  
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
  
  # Biểu đồ Actual vs Predicted (train & test)
  output$pred_plot <- renderPlot({
    plot_data <- rbind(
      data.frame(Actual=train_y, Predicted=pred_train, Set="Train"),
      data.frame(Actual=test_y, Predicted=pred_test, Set="Test")
    )
    
    ggplot(plot_data, aes(x=Predicted, y=Actual, color=Set)) +
      geom_point(size=4, alpha=0.7) +
      geom_smooth(method="lm", se=FALSE, size=1.2) +
      ggtitle("Biểu đồ: Dự đoán vs Thực tế (G3)", subtitle="Mô hình XGBoost") +
      xlab("Predicted G3") + ylab("Actual G3") +
      theme_light(base_size = 16)
  })
}

# -------------------------------
# 6️⃣ Chạy Shiny App
# -------------------------------
runApp(list(ui=ui, server=server))
