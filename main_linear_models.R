# ===============================================================
# 🧩 main_linear_models.R — Prediction Module (4 Linear Models)
# ===============================================================

library(glmnet)
library(ggplot2)

# --- 1. Đọc dữ liệu ---
data <- read.csv("student_performance_clean.csv")
data$internet <- ifelse(data$internet == "yes", 1, 0)
data$failures <- as.numeric(data$failures)
data$studytime <- as.numeric(data$studytime)

set.seed(123)
train_idx <- sample(1:nrow(data), 0.75 * nrow(data))
train <- data[train_idx, ]
test <- data[-train_idx, ]

x_train <- as.matrix(train[, c("studytime", "failures", "internet", "G1", "G2")])
y_train <- train$G3
x_test <- as.matrix(test[, c("studytime", "failures", "internet", "G1", "G2")])
y_test <- test$G3

# --- 2. Hàm đánh giá ---
rmse <- function(actual, predicted) sqrt(mean((actual - predicted)^2))
r2 <- function(actual, predicted) 1 - sum((actual - predicted)^2) / sum((actual - mean(actual))^2)

# --- 3. Huấn luyện các mô hình ---
# Linear Regression
lm_model <- lm(G3 ~ studytime + failures + internet + G1 + G2, data = train)
pred_lm <- predict(lm_model, newdata = test)

# Ridge Regression
ridge_cv <- cv.glmnet(x_train, y_train, alpha = 0)
ridge_best <- ridge_cv$lambda.min
ridge_model <- glmnet(x_train, y_train, alpha = 0, lambda = ridge_best)
pred_ridge <- predict(ridge_model, newx = x_test)

# Lasso Regression
lasso_cv <- cv.glmnet(x_train, y_train, alpha = 1)
lasso_best <- lasso_cv$lambda.min
lasso_model <- glmnet(x_train, y_train, alpha = 1, lambda = lasso_best)
pred_lasso <- predict(lasso_model, newx = x_test)

# Polynomial Regression (bậc 2)
poly_model <- lm(G3 ~ poly(G1, 2, raw = TRUE) + poly(G2, 2, raw = TRUE) +
                    studytime + failures + internet, data = train)
pred_poly <- predict(poly_model, newdata = test)

# --- 4. Tổng hợp kết quả ---
results <- data.frame(
  Model = c("Linear", "Ridge", "Lasso", "Polynomial"),
  RMSE = c(
    rmse(y_test, pred_lm),
    rmse(y_test, pred_ridge),
    rmse(y_test, pred_lasso),
    rmse(y_test, pred_poly)
  ),
  R2 = c(
    r2(y_test, pred_lm),
    r2(y_test, pred_ridge),
    r2(y_test, pred_lasso),
    r2(y_test, pred_poly)
  )
)

print(results)
write.csv(results, "linear_models_results.csv", row.names = FALSE)
cat("✅ Kết quả đã lưu vào linear_models_results.csv\n")

# --- 5. Hàm dự đoán điểm G3 ---
predict_g3 <- function(model_type, studytime, failures, internet, G1, G2) {
  new_data <- data.frame(studytime, failures, internet, G1, G2)
  
  if (model_type == "Linear") {
    return(predict(lm_model, newdata = new_data))
  } else if (model_type == "Ridge") {
    return(predict(ridge_model, newx = as.matrix(new_data)))
  } else if (model_type == "Lasso") {
    return(predict(lasso_model, newx = as.matrix(new_data)))
  } else if (model_type == "Polynomial") {
    return(predict(poly_model, newdata = new_data))
  } else {
    stop("❌ Model không hợp lệ!")
  }
}

# --- 6. Ví dụ sử dụng ---
example_pred <- predict_g3("Polynomial", 3, 0, 1, 12, 15)
cat("🎯 Dự đoán G3 (Polynomial):", round(example_pred, 2), "\n")
