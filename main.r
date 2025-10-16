library(shiny)
library(xgboost)
library(ggplot2)
library(httr)
library(jsonlite)

# ===============================================================
# 🔑 Hàm gọi API Gemini
# ===============================================================

clean_special_chars <- function(text) {
  if (is.null(text) || text == "") return("")
  
  # Thay in đậm **...** thành <b>...</b>
  text <- gsub("\\*\\*(.*?)\\*\\*", "<b>\\1</b>", text)
  
  # Thay bullet list "* " hoặc "- " thành "• "
  text <- gsub("(^|\\n)[\\*\\-]\\s+", "\\1• ", text)
  
  # Thay tiêu đề Markdown "## " thành in đậm
  text <- gsub("(^|\\n)#+\\s*(.*?)\\n", "\\1<b>\\2</b><br/>", text)
  
  # Thay các dấu xuống dòng bằng <br/> để hiển thị đúng HTML
  text <- gsub("\\n", "<br/>", text)
  
  # Loại bỏ các ký tự Markdown đơn lẻ còn sót lại
  text <- gsub("\\*", "", text)
  
  return(text)
}

analyze_with_gemini <- function(student_info) {
  api_key <- "YOUR_KEY " # Thay YOUR_KEY bằng khóa API thực tế của bạn
  if (api_key == "") {
    return("⚠️ Chưa thiết lập GEMINI_API_KEY. Hãy dùng Sys.setenv(GEMINI_API_KEY='YOUR_KEY').")
  }

  url <- "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent"

  # Prompt ngắn gọn, yêu cầu kết quả súc tích
  prompt_text <- paste(
    "Phân tích nhanh tính cách và xu hướng học tập của học sinh dựa trên dữ liệu:",
    student_info,
    "\nViết ngắn gọn, hay ho, thêm icon, nói chuyện dễ thương, chỉ nêu: điểm mạnh, điểm yếu, xu hướng học và gợi ý cải thiện."
  )
  print(paste("Prompt to Gemini:", prompt_text))  # In prompt để debug

  body <- list(
    contents = list(list(parts = list(list(text = prompt_text)))),
    generationConfig = list(
      maxOutputTokens = 10000,    # giới hạn token đầu ra (ngắn hơn)
      temperature = 0.9,        # giảm độ sáng tạo, giúp câu trả lời súc tích
      topP = 0.9
    )
  )

  response <- httr::POST(
    url = paste0(url, "?key=", api_key),
    httr::add_headers(`Content-Type` = "application/json"),
    body = jsonlite::toJSON(body, auto_unbox = TRUE)
  )

  if (response$status_code != 200) {
    return(paste("❌ Lỗi gọi Gemini API:", response$status_code))
  }

  content_data <- httr::content(response, "parsed")
  tryCatch({
    content_data$candidates[[1]]$content$parts[[1]]$text
  }, error = function(e) "⚠️ Không thể phân tích Gemini.")
}

# ===============================================================
# 1️⃣ Đọc dữ liệu và chuẩn bị
# ===============================================================
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

# ===============================================================
# 2️⃣ Huấn luyện mô hình XGBoost
# ===============================================================
dtrain <- xgb.DMatrix(data = train_X, label = train_y)
dtest  <- xgb.DMatrix(data = test_X,  label = test_y)

params <- list(objective="reg:squarederror", eta=0.1, max_depth=5, subsample=0.8)
model <- xgb.train(params=params, data=dtrain, nrounds=100, watchlist=list(train=dtrain), verbose=0)

# ===============================================================
# 3️⃣ Hàm tính RMSE và R²
# ===============================================================
rmse_fun <- function(y_true, y_pred) sqrt(mean((y_true - y_pred)^2))
r2_fun   <- function(y_true, y_pred) 1 - sum((y_true - y_pred)^2)/sum((y_true - mean(y_true))^2)

pred_train <- predict(model, dtrain)
pred_test  <- predict(model, dtest)

rmse_train <- rmse_fun(train_y, pred_train)
r2_train   <- r2_fun(train_y, pred_train)

rmse_test  <- rmse_fun(test_y, pred_test)
r2_test    <- r2_fun(test_y, pred_test)

# ===============================================================
# 4️⃣ Giao diện Shiny
# ===============================================================
ui <- fluidPage(
  titlePanel("📊 Dự đoán điểm G3 học sinh + 🧠 Phân tích Gemini"),
  
  sidebarLayout(
    sidebarPanel(
      numericInput("studytime", "Thời gian học (1-4):", value=1, min=1, max=4),
      numericInput("failures", "Số lần trượt (0-3):", value=0, min=0, max=3),
      selectInput("internet", "Có internet:", choices=c("Yes"=1, "No"=0)),
      numericInput("G1", "Điểm G1 (0-20):", value=10, min=0, max=20),
      numericInput("G2", "Điểm G2 (0-20):", value=10, min=0, max=20),
      actionButton("predict_btn", "✅ Dự đoán"),
      actionButton("gemini_btn", "🧩 Phân tích Gemini"),
      hr(),
      h4("Đánh giá mô hình:"),
      verbatimTextOutput("model_metrics")
    ),
    
    mainPanel(
      h3("🎯 Kết quả dự đoán:"),
      verbatimTextOutput("prediction"),
      hr(),
      h3("🧠 Phân tích Gemini:"),
      uiOutput("gemini_analysis"),
      hr(),
      h3("📈 Biểu đồ Actual vs Predicted"),
      plotOutput("pred_plot", height="500px")
    )
  )
)

# ===============================================================
# 5️⃣ Server logic
# ===============================================================
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
  
  # Khi nhấn nút phân tích Gemini
  observeEvent(input$gemini_btn, {
    req(predicted())
    
    student_info <- paste(
      "Thời gian học:", input$studytime,
      "| Số lần trượt:", input$failures,
      "| Internet:", ifelse(input$internet==1, "Có", "Không"),
      "| Điểm G1:", input$G1,
      "| Điểm G2:", input$G2,
      "| Dự đoán điểm G3:", round(predicted(), 2)
    )
    
    output$gemini_analysis <- renderText({"⏳ Đang phân tích bằng Gemini..."})
    
    analysis_result <- analyze_with_gemini(student_info)
    
    output$gemini_analysis <- renderUI({
  HTML(clean_special_chars(analysis_result))
    })
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

# ===============================================================
# 6️⃣ Chạy Shiny App
# ===============================================================
runApp(list(ui=ui, server=server))
