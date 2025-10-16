# 🎓 Hệ Thống Dự Đoán và Phân Tích Học Tập

## 📊 Tổng Quan
Hệ thống thông minh giúp dự đoán và phân tích kết quả học tập của học sinh dựa trên các yếu tố ảnh hưởng, kết hợp với khả năng phân tích tính cách thông qua AI (Gemini).

## 🔄 Quy Trình Xử Lý

### 1️⃣ Thu Thập Dữ Liệu
- 📥 Tải dữ liệu từ nguồn UCI Student Performance Dataset
- 🔄 Kết hợp dữ liệu từ hai môn học (Mathematics và Portuguese)
- 📊 Tạo tập dữ liệu tổng hợp cho phân tích

### 2️⃣ Tiền Xử Lý
- 🧹 Lọc và giữ lại các thuộc tính quan trọng
- 📝 Các yếu tố được xem xét:
  - ⏰ Thời gian học tập
  - ❌ Số lần thất bại
  - 🌐 Truy cập internet
  - 📈 Điểm số các kỳ (G1, G2, G3)

### 3️⃣ Mô Hình Dự Đoán
- 🤖 Sử dụng XGBoost cho độ chính xác cao
- 📊 Đánh giá mô hình bằng RMSE và R²
- 📈 Trực quan hóa kết quả dự đoán

### 4️⃣ Tích Hợp AI
- 🧠 Sử dụng Gemini AI để phân tích
- 💡 Đưa ra nhận xét về:
  - 💪 Điểm mạnh
  - 🎯 Điểm yếu
  - 📈 Xu hướng học tập
  - ✨ Gợi ý cải thiện

## 🛠️ Cài Đặt Môi Trường

### Các Gói R Cần Thiết:
```r
install.packages(c("plumber", "jsonlite", "ggplot2", "base64enc"), dependencies = TRUE)
install.packages("xgboost", repos="https://cran.r-project.org")
install.packages("Metrics")
install.packages(c("httr", "jsonlite"))
install.packages("shiny", repos = "https://cloud.r-project.org")
```

## 🚀 Tính Năng
- 📊 Giao diện trực quan với Shiny
- 🔮 Dự đoán điểm G3
- 🧠 Phân tích tính cách học tập
- 📈 Biểu đồ so sánh kết quả
- 💡 Gợi ý cải thiện cá nhân hóa