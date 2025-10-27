# ===============================================================
# 🔹 1. Cài đặt & nạp thư viện
# ===============================================================
if (!require(tidyverse)) install.packages("tidyverse")
if (!require(caret)) install.packages("caret")
if (!require(glmnet)) install.packages("glmnet")
# if (!require(Metrics)) install.packages("Metrics") # Không cần thiết nếu dùng caret
if (!require(xgboost)) install.packages("xgboost")
if (!require(ggplot2)) install.packages("ggplot2")
if (!require(gridExtra)) install.packages("gridExtra")

library(tidyverse)
library(caret)
library(glmnet)
library(xgboost)
library(ggplot2)
library(gridExtra)

# =Caret xung đột với Metrics ở hàm R2, nên chúng ta sẽ chỉ dùng caret
# library(Metrics) 

# ===============================================================
# 🔹 2. Đọc và xử lý dữ liệu
# ===============================================================
data <- read.csv("student_performance_clean.csv")

# Chuẩn hóa dữ liệu 'internet' (yes/no -> 1/0)
data$internet <- ifelse(data$internet == "yes", 1, 0)

# Xác định features (X) và target (y)
X <- data %>% select(studytime, failures, internet, G1, G2)
y <- data$G3

# Chia dữ liệu train/test (80/20)
set.seed(42) # Để đảm bảo kết quả có thể lặp lại
train_index <- createDataPartition(y, p = 0.8, list = FALSE)
X_train <- X[train_index, ]
X_test  <- X[-train_index, ]
y_train <- y[train_index]
y_test  <- y[-train_index]

# ===============================================================
# 🔹 3. Linear Regression (Hồi quy tuyến tính)
# ===============================================================
model_linear <- lm(y_train ~ ., data = X_train)
pred_linear <- predict(model_linear, newdata = X_test)

# FIX: Dùng hàm của caret: RMSE(pred, obs) và R2(pred, obs)
rmse_linear <- RMSE(pred_linear, y_test)
r2_linear <- R2(pred_linear, y_test)

# ===============================================================
# 🔹 4. Ridge Regression (alpha = 0)
# ===============================================================
X_train_mat <- as.matrix(X_train)
X_test_mat  <- as.matrix(X_test)

ridge_model <- cv.glmnet(X_train_mat, y_train, alpha = 0)
# FIX: Thêm as.vector() để chuyển kết quả từ matrix về vector
ridge_pred <- as.vector(predict(ridge_model, s = ridge_model$lambda.min, newx = X_test_mat))

rmse_ridge <- RMSE(ridge_pred, y_test)
r2_ridge <- R2(ridge_pred, y_test)

# ===============================================================
# 🔹 5. Lasso Regression (alpha = 1)
# ===============================================================
lasso_model <- cv.glmnet(X_train_mat, y_train, alpha = 1)
# FIX: Thêm as.vector()
lasso_pred <- as.vector(predict(lasso_model, s = lasso_model$lambda.min, newx = X_test_mat))

rmse_lasso <- RMSE(lasso_pred, y_test)
r2_lasso <- R2(lasso_pred, y_test)

# ===============================================================
# 🔹 6. Polynomial Regression (bậc 2)
# ===============================================================

# FIX: Sửa lỗi Data Leakage
# Chỉ tạo biến bậc 2 trên tập train và test một cách riêng biệt
X_train_poly <- X_train %>% mutate(
  studytime2 = studytime^2,
  failures2 = failures^2,
  G1_2 = G1^2,
  G2_2 = G2^2
)

X_test_poly <- X_test %>% mutate(
  studytime2 = studytime^2,
  failures2 = failures^2,
  G1_2 = G1^2,
  G2_2 = G2^2
)

model_poly <- lm(y_train ~ ., data = X_train_poly)
pred_poly <- predict(model_poly, newdata = X_test_poly)

rmse_poly <- RMSE(pred_poly, y_test)
r2_poly <- R2(pred_poly, y_test)

# ===============================================================
# 🔹 7. XGBoost Regression
# (Giữ lại để so sánh với các mô hình linear theo yêu cầu dự án)
# ===============================================================
dtrain <- xgb.DMatrix(data = as.matrix(X_train), label = y_train)
dtest  <- xgb.DMatrix(data = as.matrix(X_test), label = y_test)

params <- list(objective = "reg:squarederror", eta = 0.1, max_depth = 5)
xgb_model <- xgb.train(params = params, data = dtrain, nrounds = 100, verbose = 0)

xgb_pred <- predict(xgb_model, dtest)

rmse_xgb <- RMSE(xgb_pred, y_test)
r2_xgb <- R2(xgb_pred, y_test)

# ===============================================================
# 🔹 8. Tổng hợp kết quả
# ===============================================================
results <- data.frame(
  Model = c("Linear", "Ridge", "Lasso", "Polynomial", "XGBoost"),
  RMSE = c(rmse_linear, rmse_ridge, rmse_lasso, rmse_poly, rmse_xgb),
  R2 = c(r2_linear, r2_ridge, r2_lasso, r2_poly, r2_xgb)
)

print(results)

# ===============================================================
# 🔹 9. Biểu đồ so sánh
# ===============================================================

# FIX: Dùng reorder() để tự động sắp xếp cột theo giá trị
# reorder(Model, -R2) -> Sắp xếp theo R2 giảm dần
p1 <- ggplot(results, aes(x = reorder(Model, -R2), y = R2, fill = Model)) +
  geom_bar(stat = "identity", width = 0.6) +
  theme_minimal(base_size = 14) +
  ggtitle("So sánh R² giữa các mô hình") +
  ylab("R² (Càng cao càng tốt)") +
  xlab("Mô hình") +
  geom_text(aes(label = round(R2, 3)), vjust = -0.5, size = 5) +
  scale_fill_brewer(palette = "Set2") +
  theme(legend.position = "none") # Bỏ chú thích vì đã có tên ở trục X

# reorder(Model, RMSE) -> Sắp xếp theo RMSE tăng dần
p2 <- ggplot(results, aes(x = reorder(Model, RMSE), y = RMSE, fill = Model)) +
  geom_bar(stat = "identity", width = 0.6) +
  theme_minimal(base_size = 14) +
  ggtitle("So sánh RMSE giữa các mô hình") +
  ylab("RMSE (Càng thấp càng tốt)") +
  xlab("Mô hình") +
  geom_text(aes(label = round(RMSE, 3)), vjust = -0.5, size = 5) +
  scale_fill_brewer(palette = "Set1") +
  theme(legend.position = "none")

# Sắp xếp 2 biểu đồ cạnh nhau
grid.arrange(p1, p2, ncol = 2)

# ===============================================================
# 🔹 10. Lưu hình ra file
# ===============================================================
# Gộp 2 biểu đồ vào 1 file ảnh
combined_plot <- grid.arrange(p1, p2, ncol = 2)
ggsave("model_comparison.png", plot = combined_plot, width = 16, height = 7, dpi = 300)