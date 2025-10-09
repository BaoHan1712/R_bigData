# ===============================================================
#  run_api.R - Chạy REST API R bằng plumber
# ===============================================================

library(plumber)

message("[INFO] Khởi động API tại http://127.0.0.1:8000 ...")

pr <- plumb("model_api.R")
pr$run(host = "0.0.0.0", port = 8000)
