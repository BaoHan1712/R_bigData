# ===============================================================
# 🔹 1. Cài đặt & nạp thư viện
# ===============================================================
if (!require(tidyverse)) install.packages("tidyverse")
if (!require(caret)) install.packages("caret")
if (!require(glmnet)) install.packages("glmnet")
if (!require(xgboost)) install.packages("xgboost")
if (!require(ggplot2)) install.packages("ggplot2")
if (!require(gridExtra)) install.packages("gridExtra")

library(tidyverse)
library(caret)
library(glmnet)
library(xgboost)
library(ggplot2)
library(gridExtra)

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
set.seed(42)
train_index <- createDataPartition(y, p = 0.8, list = FALSE)
X_train <- X[train_index, ]
X_test  <- X[-train_index, ]
y_train <- y[train_index]
y_test  <- y[-train_index]

# ===============================================================
# 🔹 3. Linear Regression
# ===============================================================
model_linear <- lm(y_train ~ ., data = X_train)
pred_linear <- predict(model_linear, newdata = X_test)
rmse_linear <- RMSE(pred_linear, y_test)
r2_linear <- R2(pred_linear, y_test)

# ===============================================================
# 🔹 4. Ridge Regression (alpha = 0)
# ===============================================================
ridge_model <- cv.glmnet(as.matrix(X_train), y_train, alpha = 0)
ridge_pred <- as.vector(predict(ridge_model, s = ridge_model$lambda.min,
                                newx = as.matrix(X_test)))
rmse_ridge <- RMSE(ridge_pred, y_test)
r2_ridge <- R2(ridge_pred, y_test)

# ===============================================================
# 🔹 5. Lasso Regression (alpha = 1)
# ===============================================================
lasso_model <- cv.glmnet(as.matrix(X_train), y_train, alpha = 1)
lasso_pred <- as.vector(predict(lasso_model, s = lasso_model$lambda.min,
                                newx = as.matrix(X_test)))
rmse_lasso <- RMSE(lasso_pred, y_test)
r2_lasso <- R2(lasso_pred, y_test)

# ===============================================================
# 🔹 6. Polynomial Regression (bậc 2)
# ===============================================================
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
# ===============================================================
dtrain <- xgb.DMatrix(data = as.matrix(X_train), label = y_train)
dtest  <- xgb.DMatrix(data = as.matrix(X_test), label = y_test)
params <- list(objective = "reg:squarederror", eta = 0.1, max_depth = 5)
xgb_model <- xgb.train(params = params, data = dtrain, nrounds = 100, verbose = 0)
xgb_pred <- predict(xgb_model, dtest)
rmse_xgb <- RMSE(xgb_pred, y_test)
r2_xgb <- R2(xgb_pred, y_test)

# ===============================================================
# 🔹 8. Tổng hợp kết quả RMSE và R2
# ===============================================================
results <- data.frame(
  Model = c("Linear", "Ridge", "Lasso", "Polynomial", "XGBoost"),
  RMSE = c(rmse_linear, rmse_ridge, rmse_lasso, rmse_poly, rmse_xgb),
  R2 = c(r2_linear, r2_ridge, r2_lasso, r2_poly, r2_xgb)
)
print(results)

# ===============================================================
# 🔹 9. Biểu đồ so sánh RMSE và R2
# ===============================================================
p1 <- ggplot(results, aes(x = reorder(Model, -R2), y = R2, fill = Model)) +
  geom_bar(stat = "identity", width = 0.6) +
  theme_minimal(base_size = 14) +
  ggtitle("So sánh R² giữa các mô hình") +
  geom_text(aes(label = round(R2, 3)), vjust = -0.5, size = 5) +
  theme(legend.position = "none")

p2 <- ggplot(results, aes(x = reorder(Model, RMSE), y = RMSE, fill = Model)) +
  geom_bar(stat = "identity", width = 0.6) +
  theme_minimal(base_size = 14) +
  ggtitle("So sánh RMSE giữa các mô hình") +
  geom_text(aes(label = round(RMSE, 3)), vjust = -0.5, size = 5) +
  theme(legend.position = "none")

combined_plot <- grid.arrange(p1, p2, ncol = 2)
ggsave("model_comparison.png", plot = combined_plot, width = 16, height = 7, dpi = 300)

# ===============================================================
# 🔹 10. ĐÁNH GIÁ PRECISION - RECALL - F1 CHO TỪNG MÔ HÌNH LINEAR
# ===============================================================

# Chuyển thành bài toán phân loại: đạt (>=10) và không đạt (<10)
y_test_class <- ifelse(y_test >= 10, 1, 0)

# Hàm tính và vẽ các chỉ số
evaluate_and_plot <- function(model_name, pred_values, y_test_class) {
  pred_class <- ifelse(pred_values >= 10, 1, 0)
  cm <- confusionMatrix(as.factor(pred_class), as.factor(y_test_class), positive = "1")
  
  precision <- cm$byClass["Precision"]
  recall <- cm$byClass["Recall"]
  f1 <- cm$byClass["F1"]
  
  metrics <- data.frame(
    Metric = c("Precision", "Recall", "F1-score"),
    Value = c(precision, recall, f1)
  )
  
  p <- ggplot(metrics, aes(x = Metric, y = Value, fill = Metric)) +
    geom_bar(stat = "identity", width = 0.6) +
    theme_minimal(base_size = 14) +
    ggtitle(paste("Precision - Recall - F1 (", model_name, ")", sep = "")) +
    geom_text(aes(label = round(Value, 3)), vjust = -0.5, size = 5) +
    theme(legend.position = "none")
  
  filename <- paste0("precision_recall_f1_", tolower(model_name), ".png")
  ggsave(filename, plot = p, width = 7, height = 6, dpi = 300)
  print(paste("✅ Đã lưu:", filename))
}

# Đánh giá từng mô hình hồi quy
evaluate_and_plot("Linear", pred_linear, y_test_class)
evaluate_and_plot("Ridge", ridge_pred, y_test_class)
evaluate_and_plot("Lasso", lasso_pred, y_test_class)
evaluate_and_plot("Polynomial", pred_poly, y_test_class)
evaluate_and_plot("XGBoost", xgb_pred, y_test_class)

print("🎯 Đã hoàn tất đánh giá và lưu tất cả biểu đồ.")
