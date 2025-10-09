# ===============================================================
#  model_api.R - REST API dự đoán điểm học sinh bằng R + plumber
# ===============================================================

# Cài gói nếu chưa có (chỉ cần chạy 1 lần)
# install.packages(c("plumber", "jsonlite", "ggplot2"))

library(plumber)
library(jsonlite)
library(ggplot2)

# -------------------------------
# 1️⃣ Đọc dữ liệu và huấn luyện
# -------------------------------
message("[INFO] Đang đọc dữ liệu student_scores.csv ...")

# Kiểm tra tồn tại file
if (!file.exists("student_scores.csv")) {
  stop("[ERROR] Không tìm thấy file student_scores.csv trong thư mục hiện tại!")
}

data <- read.csv("student_scores.csv")

if (!all(c("Hours_Studied", "Score") %in% names(data))) {
  stop("[ERROR] Dataset phải có 2 cột: Hours_Studied, Score.")
}

set.seed(123)
train_index <- sample(1:nrow(data), 0.7 * nrow(data))
train_data <- data[train_index, ]
test_data  <- data[-train_index, ]

model <- lm(Score ~ Hours_Studied, data = train_data)
message("[INFO] Mô hình đã được huấn luyện thành công.")
message("[INFO] Công thức: Score = ",
        round(coef(model)[1], 2), " + ", round(coef(model)[2], 2), " * Hours_Studied")

# -------------------------------
# 2️⃣ Định nghĩa API endpoints
# -------------------------------

#* @apiTitle Student Score Prediction API
#* @apiDescription API dự đoán điểm học sinh bằng hồi quy tuyến tính R.

#* Kiểm tra trạng thái server
#* @get /status
function() {
  list(status = "online", model = "linear regression", data_rows = nrow(data))
}

#* Dự đoán điểm từ số giờ học
#* @get /predict
#* @param hours:Number of study hours
function(hours = 5) {
  hours <- as.numeric(hours)
  if (is.na(hours)) {
    return(list(error = "Tham số 'hours' phải là số."))
  }
  predicted <- predict(model, newdata = data.frame(Hours_Studied = hours))
  list(hours = hours, predicted_score = round(predicted, 2))
}

#* Trả về JSON gồm dữ liệu thật + dự đoán (phục vụ Flask hoặc JS vẽ biểu đồ)
#* @get /dataset
function() {
  pred <- predict(model, newdata = data)
  df <- data.frame(Hours_Studied = data$Hours_Studied,
                   Actual = data$Score,
                   Predicted = round(pred, 2))
  toJSON(df, pretty = TRUE)
}

#* Xuất hình đồ thị thực tế vs hồi quy tuyến tính
#* @serializer contentType list(type="image/png")
#* @get /plot
function() {
  pred <- predict(model, newdata = data)
  png(filename = NULL, width = 700, height = 500)
  ggplot(data, aes(x = Hours_Studied, y = Score)) +
    geom_point(color = "blue", size = 3) +
    geom_line(aes(y = pred), color = "red", size = 1.2) +
    ggtitle("Actual vs Predicted Scores") +
    xlab("Hours Studied") + ylab("Score") +
    theme_minimal()
  dev.off()
}
