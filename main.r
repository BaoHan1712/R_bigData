library(shiny)
# library(xgboost) # KHÔNG CÒN CẦN THIẾT
library(ggplot2)
library(httr)
library(jsonlite)

# ===============================================================
# 🔑 Hàm gọi API Gemini (Giữ nguyên)
# ===============================================================

clean_special_chars <- function(text) {
  if (is.null(text) || text == "") return("")
  text <- gsub("\\*\\*(.*?)\\*\\*", "<b>\\1</b>", text)
  text <- gsub("(^|\\n)[\\*\\-]\\s+", "\\1• ", text)
  text <- gsub("(^|\\n)#+\\s*(.*?)\\n", "\\1<b>\\2</b><br/>", text)
  text <- gsub("\\n", "<br/>", text)
  text <- gsub("\\*", "", text)
  return(text)
}

analyze_with_gemini <- function(student_info) {
  # ==========================================================
  # 🚨 BẮT BUỘC: HÃY DÙNG KEY MỚI (ĐÃ KÍCH HOẠT API) TẠI ĐÂY
  # ==========================================================
  api_key <- "API" # Thay bằng GEMINI_API_KEY mới của bạn
  
  if (api_key == "YOUR_NEW_API_KEY_HERE" || api_key == "") {
    return("⚠️ Vui lòng thiết lập GEMINI_API_KEY mới đã được kích hoạt.")
  }
  
  # ==========================================================
  # SỬA LỖI 404: Dùng mô hình mới nhất "gemini-1.5-pro-latest"
  # và endpoint "v1beta"
  # ==========================================================
  url <- "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent"
  
  prompt_text <- paste(
    "Phân tích nhanh tính cách và xu hướng học tập của học sinh dựa trên dữ liệu:",
    student_info,
    "\nViết ngắn gọn, hay ho, thêm icon, nói chuyện dễ thương, chỉ nêu: điểm mạnh, điểm yếu, xu hướng học và gợi ý cải thiện."
  )
  print(paste("Prompt to Gemini:", prompt_text)) 

  body <- list(
    contents = list(list(parts = list(list(text = prompt_text)))),
    generationConfig = list(
      maxOutputTokens = 10000, 
      temperature = 0.9,
      topP = 0.9
    )
  )
  
  response <- httr::POST(
    url = paste0(url, "?key=", api_key),
    httr::add_headers(`Content-Type` = "application/json"),
    body = jsonlite::toJSON(body, auto_unbox = TRUE)
  )
  
  if (response$status_code != 200) {
    # In ra nội dung lỗi để debug
    print(httr::content(response, "text", encoding = "UTF-8"))
    return(paste("❌ Lỗi gọi Gemini API:", response$status_code))
  }
  
  content_data <- httr::content(response, "parsed")
  tryCatch({
    content_data$candidates[[1]]$content$parts[[1]]$text
  }, error = function(e) "⚠️ Không thể phân tích Gemini.")
}

# ===============================================================
# 1️⃣ Đọc dữ liệu và chuẩn bị (Giữ nguyên)
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

# THAY ĐỔI: Chúng ta cần G3 trong train_data, nhưng cũng cần y riêng để đánh giá
train_y <- train_data$G3
test_y  <- test_data$G3

# ===============================================================
# 2️⃣ THAY ĐỔI: Huấn luyện mô hình Linear Regression
# ===============================================================

# Dùng công thức G3 ~ . (dự đoán G3 dựa trên tất cả các cột còn lại)
# Hàm lm() sử dụng data.frame (train_data)
model <- lm(G3 ~ ., data = train_data)

# Bạn có thể xem tóm tắt mô hình trong Console
print(summary(model))

# ===============================================================
# 3️⃣ Hàm tính RMSE và R² (Giữ nguyên) và Đánh giá
# ===============================================================
rmse_fun <- function(y_true, y_pred) sqrt(mean((y_true - y_pred)^2))
r2_fun   <- function(y_true, y_pred) 1 - sum((y_true - y_pred)^2)/sum((y_true - mean(y_true))^2)

# THAY ĐỔI: Dự đoán bằng mô hình lm
pred_train <- predict(model, newdata = train_data)
pred_test  <- predict(model, newdata = test_data)

# Tính toán lỗi (dùng train_y và test_y đã định nghĩa ở mục 1)
rmse_train <- rmse_fun(train_y, pred_train)
r2_train   <- r2_fun(train_y, pred_train)

rmse_test  <- rmse_fun(test_y, pred_test)
r2_test    <- r2_fun(test_y, pred_test)

# ===============================================================
# 4️⃣ Giao diện Shiny (Giữ nguyên)
# ===============================================================
ui <- fluidPage(
  titlePanel("📊 Dự đoán điểm G3 học sinh + 🧠 Phân tích Gemini (Dùng Linear)"), # Sửa tiêu đề
  
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
      h4("Đánh giá mô hình (Linear):"), # Sửa tiêu đề
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
  
  # Hiển thị RMSE và R² (Tự động cập nhật)
  output$model_metrics <- renderText({
    paste0(
      "Train: RMSE=", round(rmse_train,2), ", R²=", round(r2_train,3), "\n",
      "Test : RMSE=", round(rmse_test,2),  ", R²=", round(r2_test,3)
    )
  })
  
  # THAY ĐỔI: Dự đoán khi nhấn nút (dùng logic của lm)
  predicted <- eventReactive(input$predict_btn, {
    new_data <- data.frame(
      studytime = input$studytime,
      failures  = input$failures,
      internet  = as.numeric(input$internet),
      G1        = input$G1,
      G2        = input$G2
    )
    # THAY ĐỔI: Dùng predict() cho lm với 'newdata' là data.frame
    predict(model, newdata = new_data)
  })
  
  output$prediction <- renderText({
    req(predicted())
    paste0("Điểm G3 dự đoán: ", round(predicted(), 2))
  })
  
# Logic gọi Gemini (ĐÃ SỬA LỖI)
  observeEvent(input$gemini_btn, {
    req(predicted()) # Yêu cầu phải có dự đoán trước
    
    student_info <- paste(
      "Thời gian học:", input$studytime,
      "| Số lần trượt:", input$failures,
      "| Internet:", ifelse(input$internet==1, "Có", "Không"),
      "| Điểm G1:", input$G1,  # <--- ĐÃ SỬA
      "| Điểm G2:", input$G2,
      "| Dự đoán điểm G3:", round(predicted(), 2)
    )
    
    # Hiển thị thông báo "Đang tải"
    output$gemini_analysis <- renderText({"⏳ Đang phân tích bằng Gemini..."})
    
    # Gọi API
    analysis_result <- analyze_with_gemini(student_info)
    
    # Hiển thị kết quả
    output$gemini_analysis <- renderUI({
      HTML(clean_special_chars(analysis_result))
    })
  })
  
  # Biểu đồ Actual vs Predicted (Giữ nguyên, nó tự động cập nhật)
  output$pred_plot <- renderPlot({
    plot_data <- rbind(
      data.frame(Actual=train_y, Predicted=pred_train, Set="Train"),
      data.frame(Actual=test_y, Predicted=pred_test, Set="Test")
    )
    
    ggplot(plot_data, aes(x=Predicted, y=Actual, color=Set)) +
      geom_point(size=4, alpha=0.7) +
      geom_smooth(method="lm", se=FALSE, size=1.2) +
      ggtitle("Biểu đồ: Dự đoán vs Thực tế (G3)", subtitle="Mô hình Linear Regression") + # Sửa tiêu đề
      xlab("Predicted G3") + ylab("Actual G3") +
      theme_light(base_size = 16)
  })
}

# ===============================================================
# 6️⃣ Chạy Shiny App
# ===============================================================
runApp(list(ui=ui, server=server))